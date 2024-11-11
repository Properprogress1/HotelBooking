// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {HotelBooking} from "../src/BookHotel.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MTK") {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }
}

contract HotelBookingTest is Test {
    HotelBooking public hotelBooking;
    MockERC20 public token;
    address owner = address(0x1);
    address guest = address(0x2);
    uint256 roomPrice = 1e18; // 1 MTK
    uint256 roomNumber = 1;
    uint256 checkIn;
    uint256 checkOut;

    function setUp() public {
        // Start as owner to deploy contracts and mint tokens
        vm.startPrank(owner);
        token = new MockERC20();  // Deploy MockERC20 token contract
        hotelBooking = new HotelBooking(address(token), roomPrice); // Deploy HotelBooking with token and price

        // Transfer tokens from owner's balance to guest
        token.transfer(guest, roomPrice * 2);
        vm.stopPrank();

        // Guest approves contract to use tokens
        vm.startPrank(guest);
        token.approve(address(hotelBooking), roomPrice * 2);
        vm.stopPrank();

        // Set check-in and check-out dates
        checkIn = block.timestamp + 1 days;
        checkOut = block.timestamp + 2 days;
    }

    function testBookRoom() public {
        vm.startPrank(guest);

        hotelBooking.bookRoom(roomNumber, checkIn, checkOut);
        (address bookedGuest, uint256 bookedRoom, uint256 bookedCheckIn, uint256 bookedCheckOut, , bool isActive) = hotelBooking.bookings(roomNumber);

        assertEq(bookedGuest, guest);
        assertEq(bookedRoom, roomNumber);
        assertEq(bookedCheckIn, checkIn);
        assertEq(bookedCheckOut, checkOut);
        assertTrue(isActive);

        vm.stopPrank();
    }

    function testCancelBooking() public {
        vm.startPrank(guest);

        hotelBooking.bookRoom(roomNumber, checkIn, checkOut);

        hotelBooking.cancelBooking(roomNumber);
        (, , , , , bool isActive) = hotelBooking.bookings(roomNumber);

        assertFalse(isActive, "Room should be marked inactive after cancellation");

        vm.stopPrank();
    }

    function testRateService() public {
        vm.startPrank(guest);

        uint8 rating = 4;
        hotelBooking.rateService(rating);
        uint8 storedRating = hotelBooking.getRating(guest);

        assertEq(storedRating, rating, "Rating should be recorded correctly");

        vm.stopPrank();
    }

    function testSetRoomPrice() public {
        vm.startPrank(owner);

        uint256 newRoomPrice = 2e18;
        hotelBooking.setRoomPrice(newRoomPrice);

        assertEq(hotelBooking.roomPrice(), newRoomPrice, "Room price should be updated");

        vm.stopPrank();
    }

    function testWithdrawFunds() public {
        vm.startPrank(guest);

        hotelBooking.bookRoom(roomNumber, checkIn, checkOut);

        vm.stopPrank();
        vm.startPrank(owner);

        uint256 initialOwnerBalance = token.balanceOf(owner);
        hotelBooking.withdraw(roomPrice);

        assertEq(token.balanceOf(owner), initialOwnerBalance + roomPrice, "Owner should receive withdrawn funds");

        vm.stopPrank();
    }

    function testCheckRoomAvailability() public {
        bool isAvailable = hotelBooking.isRoomAvailable(roomNumber);
        assertTrue(isAvailable, "Room should be available initially");

        vm.startPrank(guest);
        hotelBooking.bookRoom(roomNumber, checkIn, checkOut);
        isAvailable = hotelBooking.isRoomAvailable(roomNumber);
        assertFalse(isAvailable, "Room should not be available after booking");

        vm.stopPrank();
    }
}