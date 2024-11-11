// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract HotelBooking is ReentrancyGuard {
    address public owner;
    uint256 public roomPrice;
    IERC20 public token;
    uint256 public totalRooms = 20;
    uint256 public maxBookingDuration = 30 days; // Optional maximum booking duration

    struct Booking {
        address guest;
        uint256 roomNumber;
        uint256 checkIn;
        uint256 checkOut;
        uint8 rating;
        bool isActive;
    }

    mapping(uint256 => Booking) public bookings; // room number to booking
    mapping(address => uint8) public ratings; // customer to rating
    uint256 public bookedRooms;

    event RoomBooked(address indexed guest, uint256 roomNumber, uint256 checkIn, uint256 checkOut);
    event RatingGiven(address indexed guest, uint8 rating);
    event RoomCancelled(uint256 roomNumber, address indexed guest);
    event RoomPriceUpdated(uint256 newPrice);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }

    constructor(address _tokenAddress, uint256 _roomPrice) {
        owner = msg.sender;
        roomPrice = _roomPrice;
        token = IERC20(_tokenAddress);
    }

    // Update room price
    function setRoomPrice(uint256 newPrice) external onlyOwner {
        roomPrice = newPrice;
        emit RoomPriceUpdated(newPrice);
    }

    // Book a room
    function bookRoom(uint256 roomNumber, uint256 checkIn, uint256 checkOut) external nonReentrant {
        require(roomNumber > 0 && roomNumber <= totalRooms, "Invalid room number.");
        require(bookings[roomNumber].isActive == false, "Room is already booked.");
        require(checkIn > block.timestamp, "Check-in time must be in the future.");
        require(checkOut > checkIn, "Check-out time must be after check-in.");
        require(checkOut - checkIn <= maxBookingDuration, "Exceeds maximum booking duration.");

        // Transfer payment from guest
        require(token.transferFrom(msg.sender, address(this), roomPrice), "Payment failed.");

        bookings[roomNumber] = Booking({
            guest: msg.sender,
            roomNumber: roomNumber,
            checkIn: checkIn,
            checkOut: checkOut,
            rating: 0,
            isActive: true
        });

        bookedRooms++;
        emit RoomBooked(msg.sender, roomNumber, checkIn, checkOut);
    }

    // Rate the service
    function rateService(uint8 _rating) external nonReentrant {
        require(_rating >= 1 && _rating <= 5, "Rating should be between 1 and 5.");
        require(ratings[msg.sender] == 0, "You have already rated.");

        ratings[msg.sender] = _rating;
        emit RatingGiven(msg.sender, _rating);
    }

    // Cancel booking and refund if applicable
    function cancelBooking(uint256 roomNumber) external nonReentrant {
        require(bookings[roomNumber].guest == msg.sender, "You did not book this room.");
        require(bookings[roomNumber].isActive == true, "Room is not booked.");

        if (block.timestamp < bookings[roomNumber].checkIn) {
            // Refund if cancellation happens before check-in
            require(token.transfer(msg.sender, roomPrice), "Refund failed.");
        }

        bookings[roomNumber].isActive = false;
        bookedRooms--;

        emit RoomCancelled(roomNumber, msg.sender);
    }

    // Withdraw funds by owner
    function withdraw(uint256 amount) external onlyOwner nonReentrant {
        require(token.transfer(owner, amount), "Withdraw failed.");
    }

    // Get rating of a customer
    function getRating(address customer) external view returns (uint8) {
        return ratings[customer];
    }

    // Check room availability
    function isRoomAvailable(uint256 roomNumber) external view returns (bool) {
        return !bookings[roomNumber].isActive;
    }
}
