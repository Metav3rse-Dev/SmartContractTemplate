// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Template is ERC721A, Ownable { // Replace Template with your own contract name
    
    mapping (address => uint256) addresses; // A mapping we might use for whitelisting
    
    uint256 collectionSize;
    uint256 publicMintStart; // Date in epoch unix time, example: 1657843200 is Friday, July 15, 2022 12:00:00 AM. You might visit https://www.epochconverter.com/ to convert your sale start date.
    uint256 whitelistMintPrice; // If we do not want to hardcode mint prices, we can set up variables and set the price later on
    uint256 publicMintPrice;

    string baseURI;

    constructor(uint256 collectionSize_) ERC721A("Name", "Symbol") { // Replace name and symbol with your own
        collectionSize = collectionSize_;
    }

    function whitelistMint(uint256 quantity) external payable callerIsUser {
        require(whitelistMintPrice>0, "Whitelist price not set yet"); // If you set a price variable, make sure it's set first
        require (msg.value == quantity * whitelistMintPrice, "Not enough ETH sent"); // Set a mint price
        require (addresses[msg.sender] >= quantity, "Not allowed to mint"); // With the mapping whitelisting, we check if the address is allowed to mint the quantity requested
        require(totalSupply() + quantity <= collectionSize, "Reached max supply"); // Make sure people cannot mint more than your collection size
        addresses[msg.sender] -= quantity; // Mapping whitelisting is more suitable for projects with small number of whitelists
                                           // If you have have a big whitelist, using a Merkle Tree or Server Side Signatures might be a better solution
                                           // We subtract number of quantity from the mapped address' allowance
        _mint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable callerIsUser {
        require(publicMintPrice>0, "Whitelist price not set yet"); // If you set a price variable, make sure it's set first
        require (msg.value == quantity * publicMintPrice, "Not enough ETH sent"); // Set a mint price
        require (quantity < 5, "You can mint 5 tokens at once"); // We might set an upper limit to the number of tokens minted per transaction
        require(publicMintStart != 0 && block.timestamp >= publicMintStart, "Sale has not started yet"); // We use epoch unix time. You might visit https://www.epochconverter.com/ to convert your sale start date.
        require(totalSupply() + quantity <= collectionSize, "Reached max supply"); // Make sure people cannot mint more than your collection size
        _mint(msg.sender, quantity);
    }

    // You might want to give yourself option to mint tokens easily
    function ownerMint(uint256 quantity) external onlyOwner {
        _mint(msg.sender, quantity);
    }

    // Airdrop a token to an address
    function airdropToAddress(address recipient, uint256 quantity) external onlyOwner {
        _mint(recipient, quantity);
    }

    // Set the public start date as epoch unix time
    function setPublicStartDate(uint256 startDate) external onlyOwner {
        publicMintStart = startDate;
    }

    // Set the price variables. Like all setup functions, we use onlyOwner modifier to make sure only the contract uploader, or owner can call these functions.
    // We can use transferOwnership function to set another address as the owner
    function setWhitelistPrice(uint64 price) external onlyOwner {
      whitelistMintPrice = price;
    }

    function setPublicPrice(uint64 price) external onlyOwner {
      publicMintPrice = price;
    }

    // Add a withdraw function to the contract so we can transfer the contract's funds to a wallet
    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        // If the owner is a multi sig wallet like Gnosis Safe, this code will fail, so in that case it might be a better idea to use 
        // something like: 
        // (bool os,) = payable(msg.sender).call{value:address(this).balance}(""); 
        // require(os);
    }

    // This modifier will prevent the function to be called by other contracts
    modifier callerIsUser() {
      require(tx.origin == msg.sender, "The caller is another contract");
      _;
    }

    // A function for the owner to add whitelist addresses to the mapping. For example we can give address A 5 mint allowance, and address B 1 mint allowance and so on
    function addWhitelist(address addr, uint256 quantity) external onlyOwner {
        addresses[addr] = quantity;
    }

    // Base URI for your folder that hosts all your metadata, example base URI ipfs://QmbYwqUwm5i2ztk1dX3TFix8XGVBZEnzNYiLs3YzokbqHD/
    // Make sure you set the baseURI before minting so the tokens do not appear empty. You can update the baseURI later on to change the collection
    // This is especially useful for delayed reveals. For example you might display a placeholder gif until public sale and then update the baseURI 
    // and reveal the collection
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory URI) external onlyOwner {
      baseURI = URI;
    }

    function viewBaseURI() public view returns(string memory) {
      return _baseURI();
    }
}
