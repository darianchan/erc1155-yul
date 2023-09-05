// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";

contract ERC1155Reciever {
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes memory data) external returns(bytes4) {
        console.log("hits here $$$");
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] memory ids, uint256[] memory values, bytes memory data) external returns(bytes4) {
        console.log("hits here $$$ batch recieved");
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    fallback() external {
        console.log("do nothing");
    }
}