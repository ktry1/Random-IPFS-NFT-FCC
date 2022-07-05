const { rejects } = require("assert");
const { expect,assert } = require("chai");
const { sign } = require("crypto");
const { ethers, network, getNamedAccounts } = require("hardhat");
const { resolve } = require("path");
let contract,vrfCoordinatorV2Mock;

describe("Random NFT", function () {
    beforeEach(async function () {
        await deployments.fixture(['all']);
        const provider = ethers.getDefaultProvider(network.config.url);
        const {deployer} = await getNamedAccounts();
        const signer = new ethers.Wallet("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", provider);
        contract = await ethers.getContract("RandomIpfsNft",signer);
        vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock");
    });
describe("Constructor tests", function () {
  it("Correctly sets token URIs", async function () {
        const URIs = [];
        for(let i = 0; i<3; i++){
            URI = (await contract.getSunTokenUris(i)).toString();
            URIs.push(URI);
        } 
        expect(...URIs).to.be.equal(...[
            'ipfs://QmaVkBn2tKmjbhphU7eyztbvSQU5EXDdqRyXZtRhSGgJGo',
            'ipfs://QmYQC5aGZu2PTH8XzbJrbDnvhj3gVs7ya33H9mqUNvST3d',
            'ipfs://QmZYmH5iDbD6v3U2ixoVAjioSzvWJszDzYdbeCLquGSpVm'
          ])
        console.log("URIs are:");
        console.log(URIs);
  });
  it("Correctly sets the mint Fee", async function () {
    const mintFee = await contract.getMintFee();
    console.log(`Mint fee is ${ethers.utils.formatEther(mintFee)} ETH`);
    expect(mintFee).to.be.equal(ethers.utils.parseEther("0.01"));
  });
  it("Correctly initializes the contract", async function () {
    const initState = await contract.getInitialized();
    expect(initState).to.be.equal(true); 
  });
  it("Correctly sets the ChanceArray", async function () {
    const ChanceArray = await contract.getChanceArray();
    expect(...ChanceArray).to.be.equal(...[10, 50, 100]);
    console.log("Chance Array is:");
    console.log(ChanceArray.toString());
  });
  it("Sets the tokenCounter to zero", async function () {
    const tokenCounter = await contract.getTokenCounter();
    console.log(`Token counter is ${tokenCounter.toString()}`);
    expect(tokenCounter.toString()).to.be.equal("0");
  })
});
describe("Function call tests", function () {
    it("Reverts if not enough ETH was sent", async function () {
        await expect(contract.requestNft({value:ethers.utils.parseEther("0.001")})).to.be.revertedWith("RandomIpfsNft__NeedMoreETHSent");
    });
    it("Emits NftRequestedEvents when somebody calls requestNft()", async function () {
        await expect(contract.requestNft({value:ethers.utils.parseEther("0.01"),gasLimit:30000000}))
        .to.emit(contract, "NftRequested");
    });
    it("Mints the NFT once requestNFT has been called", async function(){
        await new Promise (async (resolve,reject)=>{
            contract.once("NftMinted", async () => {
                
                console.log("Requesting Token URI...");
                const tokenUri = await contract.getSunTokenUris(0)
                console.log("Got it! Requesting token counter...")
                const tokenCounter = await contract.getTokenCounter()
                console.log("Done! Running tests...")
                assert.equal(tokenUri.toString().includes("ipfs://"), true)
                assert.equal(tokenCounter.toString(), "1")
                resolve();
                
            })
                try{
               
                const tx = await contract.requestNft({value:ethers.utils.parseEther("0.01"),gasLimit:30000000});
                const txReceipt = await tx.wait(1);
                await vrfCoordinatorV2Mock.fulfillRandomWords(txReceipt.events[1].args.requestId, contract.address);
                }
                catch(e){
                    console.log(e);
                    reject();
                }
        })
    })
})
});