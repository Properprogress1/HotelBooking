// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {HotelBooking} from "../src/BookHotel.sol";

contract MyBooking is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        HotelBooking BMH = new HotelBooking(0xbDeaD2A70Fe794D2f97b37EFDE497e68974a296d, 1);  

        vm.stopBroadcast();
 
   }


}
