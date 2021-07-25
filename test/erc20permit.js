const fs = require("fs");
const { ethers, BigNumber } = require("ethers");

const TokenData = require("../build/contracts/CustomERC20.json");

const CustomERC20 = artifacts.require("./CustomERC20.sol");

const {
  PERMIT_TYPEHASH,
  getPermitDigest,
  getDomainSeparator,
  sign,
} = require("../utility");

const ownerPrivateKey =
  "4a233a438a7a26729b1c578d2c4832af4906d56fdcdb93e1f3e49326862ec528";

const senderPrivateKey =
  "e8bf741fada50a9a5d156631c5201c6d2c5dd38e168d246ea3cf1d313d9101bb";

const deadline = 1657121546000;

const infuraKey = fs.readFileSync(".infurakey.secret");

const RPC_PROVIDER = {
  mumbai: `https://polygon-mumbai.infura.io/v3/${infuraKey}`,
  local: `http://127.0.0.1:7545/`,
};

contract("ERC20Permit", async (accounts) => {
  it("should set allowance after a permit transaction", async () => {
    const instance = await CustomERC20.deployed();

    const owner = new ethers.Wallet(ownerPrivateKey);
    const sender = new ethers.Wallet(senderPrivateKey);
    console.log("RPC ==>", RPC_PROVIDER[process.env.NETWORK]);
    const provider = new ethers.providers.JsonRpcProvider(
      RPC_PROVIDER[process.env.NETWORK]
    );

    let customERC20 = new ethers.Contract(
      instance.address,
      TokenData.abi,
      provider
    );

    const value = 100;

    const approve = {
      owner: owner.address,
      spender: sender.address,
      value,
    };

    const nonce = parseInt((await instance.nonces(approve.owner)).toString());

    const digest = getPermitDigest(
      await instance.name(),
      instance.address,
      parseInt((await instance.getChainId()).toString()),
      approve,
      nonce,
      deadline
    );

    // Sign it
    // NOTE: Using web3.eth.sign will hash the message internally again which
    // we do not want, so we're manually signing here
    const { v, r, s } = sign(digest, Buffer.from(ownerPrivateKey, "hex"));

    const receipt = await customERC20.populateTransaction.requestPermit(
      approve.owner,
      approve.spender,
      approve.value,
      digest,
      v,
      r,
      s
    );

    customERC20 = new ethers.Contract(
      instance.address,
      CustomERC20.abi,
      sender.connect(provider)
    );

    console.log(receipt, instance.address);
    const account = sender.connect(provider);

    let tx = await account.sendTransaction({
      ...receipt,
      gasLimit: new BigNumber.from(300000),
      gasPrice: new BigNumber.from(1000000000),
    });

    console.log(await tx.wait());

    // console.log("CHAIN ID ==>", (await instance.getChainId()).toString());
  });
});
