//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./lib/EIP712Base.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/IPablockToken.sol";

contract EIP712MetaTransaction is EIP712Base, AccessControl, Pausable {
  using SafeMath for uint256;
  bytes32 private constant META_TRANSACTION_TYPEHASH =
    keccak256(
      bytes(
        "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
      )
    );

  bytes32 public constant PAYER_ROLE = keccak256("PAYER");

  event MetaTransactionExecuted(
    address userAddress,
    address payable relayerAddress,
    bytes functionSignature
  );
  mapping(address => uint256) private nonces;

  address pablockTokenAddress;
  address contractOwner;

  /*
   * Meta transaction structure.
   * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
   * He should call the desired function directly in that case.
   */
  struct MetaTransaction {
    uint256 nonce;
    address from;
    bytes functionSignature;
  }

  /**
   * MODIFIERS
   */
  modifier byOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msgSender()), "Not allowed");
    _;
  }

  modifier byPayer() {
    require(hasRole(PAYER_ROLE, msgSender()), "Not allowed as payer");
    _;
  }

  modifier hasAuth() virtual {
    require(
      (hasRole(DEFAULT_ADMIN_ROLE, msgSender()) ||
        hasRole(PAYER_ROLE, msgSender())) && !paused(),
      "Not allowed to execute meta transaction"
    );
    _;
  }

  /**
   * CONSTRUCTOR
   */
  constructor(address _payer) EIP712Base("PablockeMetaTransaction", "0.1.0") {
    contractOwner = msgSender();

    _setupRole(DEFAULT_ADMIN_ROLE, msgSender());
    setPayer(_payer);
  }

  function initialize(address _pablockTokenAddress) public byOwner {
    pablockTokenAddress = _pablockTokenAddress;
  }

  function setPayer(address _payer) public byOwner {
    _setupRole(PAYER_ROLE, _payer);
  }

  /**
   *   This function allow the execution of another cotnract function through relay method.
   *   The contract function needs to be register and gives this contract name and version to enable
   *   correct DOMAIN_SEPARATOR calcualtion. If a contract register to meta transaction but not validated on PablockToken
   *   the execution will failed.
   */
  function executeMetaTransaction(
    address destinationContract,
    address userAddress,
    bytes memory functionSignature,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) public payable hasAuth returns (bytes memory) {
    bytes4 destinationFunctionSig = convertBytesToBytes4(functionSignature);

    require(
      destinationFunctionSig != msg.sig,
      "functionSignature can not be of executeMetaTransaction method"
    );
    MetaTransaction memory metaTx = MetaTransaction({
      nonce: nonces[userAddress],
      from: userAddress,
      functionSignature: functionSignature
    });

    require(
      verify(userAddress, metaTx, sigR, sigS, sigV, destinationContract),
      "Signer and signature do not match"
    );
    nonces[userAddress] = nonces[userAddress].add(1);
    // Append userAddress at the end to extract it from calling context
    (bool success, bytes memory returnData) = destinationContract.call(
      abi.encodePacked(functionSignature, userAddress)
    );

    IPablockToken(pablockTokenAddress).receiveAndBurn(
      destinationContract,
      destinationFunctionSig,
      userAddress
    );

    require(success, string(returnData));
    emit MetaTransactionExecuted(
      userAddress,
      payable(msg.sender),
      functionSignature
    );
    return returnData;
  }

  function setPauseStatus(bool status) public byOwner {
    if (status) {
      _pause();
    } else {
      _unpause();
    }
  }

  function hashMetaTransaction(MetaTransaction memory metaTx)
    internal
    pure
    returns (bytes32)
  {
    return
      keccak256(
        abi.encode(
          // META_TRANSACTION_TYPEHASH,
          metaTx.nonce,
          metaTx.from,
          keccak256(metaTx.functionSignature)
        )
      );
  }

  function getNonce(address user) external view returns (uint256 nonce) {
    nonce = nonces[user];
  }

  function verify(
    address user,
    MetaTransaction memory metaTx,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV,
    address destinationContract
  ) internal view returns (bool) {
    // console.logBytes32(toTypedMessageHash(hashMetaTransaction(metaTx)));
    address signer = ecrecover(
      toTypedMessageHash(hashMetaTransaction(metaTx), destinationContract),
      sigV,
      sigR,
      sigS
    );

    require(signer != address(0), "Invalid signature");
    return signer == user;
  }

  function convertBytesToBytes4(bytes memory inBytes)
    internal
    pure
    returns (bytes4 outBytes4)
  {
    if (inBytes.length == 0) {
      return 0x0;
    }

    assembly {
      outBytes4 := mload(add(inBytes, 32))
    }
  }

  function msgSender() internal view returns (address sender) {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(
          mload(add(array, index)),
          0xffffffffffffffffffffffffffffffffffffffff
        )
      }
    } else {
      sender = msg.sender;
    }
    return sender;
  }
}
