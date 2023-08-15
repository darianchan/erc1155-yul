// SPDX-License-Identifier: MIT
// TODO: change floating pragma
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "./lib/YulDeployer.sol";
import "./lib/IERC1155.sol";
/*

REQUIRED INTERFACE FUNCTIONS:
-----------------------------

balanceOf(account, id)

balanceOfBatch(accounts, ids)

setApprovalForAll(operator, approved)

isApprovedForAll(account, operator)

safeTransferFrom(from, to, id, amount, data)

safeBatchTransferFrom(from, to, ids, amounts, data)

*/

contract ERC1155Test is Test {
    YulDeployer yulDeployer = new YulDeployer();

    IERC1155 token;
    address alice = address(123);
    address bob = address(456);

    function setUp() public {
        token = IERC1155(yulDeployer.deployContract("ERC1155"));
    }

    function testMintToEOA() public {
        vm.startPrank(alice);

        // mint Alice 10 tokens of id 1
        token.mint(alice, 1, 10);
        uint aliceBalance = token.balanceOf(alice, 1);
        assertEq(aliceBalance, 10);
        
        vm.stopPrank();
    }


    function testMintToERC1155Recipient(
        uint256 id,
        uint256 amount,
        bytes memory mintData
    ) public {
        // check that receiver implements the IERC1155Receiver.onERC1155Received - https://docs.openzeppelin.com/contracts/3.x/api/token/erc1155#IERC1155Receiver-onERC1155Received-address-address-uint256-uint256-bytes-
    }

    function testBatchMintToEOA(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory mintData
    ) public {

    }

    function testBatchMintToERC1155Recipient(
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory mintData
    ) public {
        // check receiver implements the IERC1155Receiver.onERC1155BatchReceived - https://docs.openzeppelin.com/contracts/3.x/api/token/erc1155#IERC1155Receiver-onERC1155BatchReceived-address-address-uint256---uint256---bytes-
    }

    // @note burn isn't in the interface requirements
    function testBurn(
        address to,
        uint256 id,
        uint256 mintAmount,
        bytes memory mintData,
        uint256 burnAmount
    ) public {

    }

    function testBatchBurn(
        address to,
        uint256[] memory ids,
        uint256[] memory mintAmounts,
        uint256[] memory burnAmounts,
        bytes memory mintData
    ) public {

    }

    // @note there is no function for just approve. It's approve all
    function testApproveAll() public {
        vm.startPrank(alice);

        token.setApprovalForAll(bob, true);
        bool isApproved = token.isApprovedForAll(alice, bob);
        assertTrue(isApproved);

        vm.stopPrank();
    }

    function testSafeTransferFromToEOA() public {

    }

    function testSafeTransferFromToERC1155Recipient() public {
        // receiver must implement IERC1155Receiver.onERC1155Received - https://docs.openzeppelin.com/contracts/3.x/api/token/erc1155#IERC1155Receiver-onERC1155Received-address-address-uint256-uint256-bytes-

    }

    function testSafeBatchTransferFromToEOA() public {

    }

    function testSafeBatchTransferFromToERC1155Recipient() public {
        // receiver must implement IERC1155Receiver.onERC1155BatchReceived - https://docs.openzeppelin.com/contracts/3.x/api/token/erc1155#IERC1155Receiver-onERC1155BatchReceived-address-address-uint256---uint256---bytes-
    }

    // @note should probably also add a test for just balanceOf()
    function testBatchBalanceOf() public {
        
    }


    // @note test failure case for each function as well?

}