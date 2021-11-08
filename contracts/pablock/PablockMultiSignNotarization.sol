// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "../PablockMetaTxReceiver.sol";
import "../PablockToken.sol"; 

pragma experimental ABIEncoderV2;


contract PablockMultiSignNotarization is PablockMetaTxReceiver {

    address private pablockTokenAddress;    

    struct Signer {
        address addr;
        bool initialized;
        bool signed;
    }

    mapping(address => uint256) private indexOfSigners;

    bytes32 private hash;
    string private uri;
    uint256 private expirationDate;
    Signer[] private signers;

    
    constructor (bytes32 _hash, address[] memory _signers, string memory _uri, uint256 _expirationDate, address _pablockTokenAddress, address _metaTxAddress ) public PablockMetaTxReceiver("PablockMultiSignNotarization", "0.2.1", _metaTxAddress) {
        hash = _hash;
        pablockTokenAddress = _pablockTokenAddress;
        uri = _uri;
        // expirationDate = _expirationDate;

        for (uint i = 0; i < _signers.length; i++) {
            signers.push(Signer(_signers[i], true, false));
            indexOfSigners[_signers[i]] = i;
        }

    }

    //Need to integrate signature to sign with meta transaction, otherwise anyone can firm any address
    function signDocument() public {

        require(signers[indexOfSigners[msgSender()]].initialized, "Signers does not exists");
        PablockToken(pablockTokenAddress).receiveAndBurn(address(this), msg.sig, msgSender());

        signers[indexOfSigners[msgSender()]].signed = true;
    }

    function getNotarizationData() public view returns (bytes32, string memory, uint256 ) {

        return (hash,  uri, expirationDate);
    }

    function getURI() public view returns (string memory){
        return uri;
    }

    function getSignerStatus(address signer) public view returns (bool){
        return signers[indexOfSigners[signer]].signed;

    } 

    function getVersion() public view returns (string memory){
        return "Version 0.1.0";
    }
}
