const { ethers } = require("ethers");
const { readFileSync } = require("fs");
const abiDecoder = require("abi-decoder");

const pablockNFTData = require("../build/contracts/PablockNFT.json");
const pablockTokenData = require("../build/contracts/PablockToken.json");
const pablockMultiSignFactoryData = require("../build/contracts/PablockMultiSignFactory.json");
const pablockMultiSignData = require("../build/contracts/PablockMultiSignNotarization.json");

function loadSecret(filename, log = false) {
  const secret = readFileSync(filename).toString().trim();
  log && console.log("Loaded Secret:", secret);
  return secret;
}

function accountByIndex(
  mnemonic,
  index = 0,
  providerURL = "http://127.0.0.1:7545"
) {
  const provider = new ethers.providers.JsonRpcProvider(providerURL);
  const wallet = ethers.Wallet.fromMnemonic(
    mnemonic,
    `m/44'/60'/0'/0/${index}`
  );
  const account = wallet.connect(provider);

  return account;
}

(async () => {
  // const infuraKey = loadSecret(".infurakey.secret");
  // const polygonProvider = new ethers.providers.JsonRpcProvider(
  //   `https://polygon-mainnet.infura.io/v3/${infuraKey}`
  // );

  //   const mnemonic = loadSecret(".mumbai.secret");
  const mnemonic =
    "divide west journey supply number poem loud surprise genuine verb warfare resemble";
  const ownerAccount = accountByIndex(mnemonic, 0, "http://127.0.0.1:7545");
  const first = accountByIndex(mnemonic, 1, "http://127.0.0.1:7545");
  const second = accountByIndex(mnemonic, 2, "http://127.0.0.1:7545");
  const seven = accountByIndex(mnemonic, 7, "http://127.0.0.1:7545");

  const provider = new ethers.providers.JsonRpcProvider(
    "http://127.0.0.1:7545"
  );
  const pablockAccount = new ethers.Wallet(
    "0xa5be2a383078efe8487077a19d4a1602ab4ceae15ff66a2765e1f96cc00734f5"
  );

  // const sevenPablockNft = new ethers.Contract(
  //   "0x80668E8e5D5e6137f3c631A2742FC1C51890b164",
  //   pablockNFTData.abi,
  //   first
  // );
  // const ownerAccount = ownerWallet.connect(polygonProvider);

  const pablockToken = new ethers.Contract(
    "0x199DA9C3b0801945c6953ee962dF18f339aB5432",
    pablockTokenData.abi,
    ownerAccount
  );

  await pablockToken.requestToken(pablockAccount.address, 10);

  // await ownerAccount.sendTransaction({
  //   to: "0xd0c1fc15Ab9160345A03091834C6b45280Bc6392",
  //   value: ethers.utils.parseEther("2"),
  //   gasPrice: 5000000000,
  //   gasLimit: 150000,
  // });

  //   await pablockToken.requestToken(second.address, 3);

  console.log(
    "First Balance:",
    (await pablockToken.balanceOf(pablockAccount.address)).toString()
  );
  //   console.log(
  //     "Second Balance:",
  //     (await pablockToken.balanceOf(second.address)).toString()
  //   );

  // const firstPablockNft = new ethers.Contract(
  //   "0x1518FA407a58dD7207C9D5b99B6D91bfF9437bF6",
  //   pablockNFTData.abi,
  //   pablockAccount.connect(provider)
  // );

  // const tx = await firstPablockNft.generateToken(
  //   2,
  //   "https://ipfs.io/ipfs/QmbqQBE7gAE4D5Q7oXJbQdoszMjWapRaDNbaLYSN2Q5Adi",
  //   {
  //     gasLimit: 600000,
  //   }
  // );

  //   console.log(tx);

  //   const receipt = await tx.wait();

  //   console.log("NFT generation result:", receipt);
})();