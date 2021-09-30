// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Book is ERC721, ReentrancyGuard {
    
    constructor() ERC721('Book Market','BMK'){}

    uint128 private bookid;

    struct book{
        uint128 bookId;
        string bookName;
        string authorName;
        address sellerAddress;
        uint128 price;
    }
    
    struct buyer{
        uint128 bookId;
        address buyerAddress;
        uint128 buyingPrice;
        
    }
    
    mapping (uint128 => address) public bookIdToSellerAddress;
    mapping (address => book) public addressToBooks;
    mapping (uint128 => book) public idTobook;
    mapping (uint128 => bool) public isSoldBook;
    mapping (uint128 => buyer) public idToBuyer;
    mapping (uint => buyer) public idToBuyerRequest;
    mapping (address => mapping (uint128 => bool)) public buyerRequestApproval;
    
    event addBook(uint128 bookId, string bookName, string authorName, address sellerAddress, uint128 price);
    event bookSold(uint128 bookId, address sellerAddress, address buyerAddress,uint128 price, bool isSold);
    
    
    function addBooktoMarket(string memory _bookName, string memory _author, uint128 _price)external {
        
        require(msg.sender != address(0),"account address invalid");
        require(_price > 0,"price must be greater than zero");
        
        bookid++;
        
        book memory tempBook = book({
            bookId : bookid,
            bookName : _bookName,
            authorName : _author,
            sellerAddress : msg.sender,
            price : _price
        });
        
        _mint(msg.sender, bookid);
        addressToBooks[msg.sender] = tempBook;
        bookIdToSellerAddress[bookid] = msg.sender;
        isSoldBook[bookid] = false;
        emit addBook(bookid, _bookName, _author, msg.sender, _price);
    }
    
    function buyBook(uint128 _bookId) payable external{
        require(isSoldBook[_bookId] == false,"book is already sold");
        require(msg.sender != bookIdToSellerAddress[bookid], "book owner cannot buy the book");
        require(uint128(msg.value) >= idTobook[_bookId].price, "price must be greater than or equal to selling price");
        
        buyer memory tempBuyer = buyer({
            bookId : _bookId,
            buyerAddress : msg.sender,
            buyingPrice : uint128(msg.value)
        });
            payable(bookIdToSellerAddress[bookid]).transfer(msg.value);
        _transfer(bookIdToSellerAddress[bookid], msg.sender, _bookId);
                
        idToBuyer[_bookId] = tempBuyer;
        isSoldBook[bookid] = true;
        
        delete idTobook[_bookId];

        emit bookSold(_bookId, idTobook[_bookId].sellerAddress, msg.sender,uint128(msg.value), true);
    }
    
    function buyRequest(uint128 _bookId, uint128 price)external {
        require(isSoldBook[_bookId] == false,"book is already sold");
        require(msg.sender != bookIdToSellerAddress[bookid], "book owner cannot buy the book");
        require(price >= 0, "price must be greater than or equal to selling price");
        
        buyer memory tempBuyer = buyer ({
            bookId : _bookId,
            buyerAddress : msg.sender,
            buyingPrice : price
        });
        
        idToBuyerRequest[_bookId] = tempBuyer;
        buyerRequestApproval[msg.sender][_bookId] = false;
        
    }

    function buyerRequestApprove(uint128 _bookId)external nonReentrant{
        require(_bookId > 0,"book ID invalid");
        require(bookIdToSellerAddress[_bookId] == msg.sender,"function must be called by the book owner!");
        address addressOfBuyer = idToBuyerRequest[_bookId].buyerAddress;
        buyerRequestApproval[addressOfBuyer][_bookId] = true;
        
    }
      
}