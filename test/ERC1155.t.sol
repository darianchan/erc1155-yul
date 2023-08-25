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

    REQUIRED INTERFACE EVENTS:
    --------------------------

    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    event URI(string _value, uint256 indexed _id);

*/

contract ERC1155Test is Test {
    YulDeployer yulDeployer = new YulDeployer();

    IERC1155 token;
    address alice = address(123);
    address bob = address(456);
    address charlie = address(789);

    uint256[] ids;
    uint256[] amounts;
    address[] accounts;

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

    function testBatchMintToEOA() public {
        vm.startPrank(alice);
        // create batch ids to mint
        ids.push(1);
        ids.push(2);
        ids.push(3);

        // create batch amounts to mint
        amounts.push(10);
        amounts.push(10);
        amounts.push(10);

        // 
        uint aliceBalance1Before = token.balanceOf(alice, 1);
        uint aliceBalance2Before = token.balanceOf(alice, 2);
        uint aliceBalance3Before = token.balanceOf(alice, 3);
        assertEq(aliceBalance1Before, 0);
        assertEq(aliceBalance2Before, 0);
        assertEq(aliceBalance3Before, 0);

        token.mintBatch(alice, ids, amounts, "");

        uint aliceBalance1After = token.balanceOf(alice, 1);
        uint aliceBalance2After = token.balanceOf(alice, 2);
        uint aliceBalance3After = token.balanceOf(alice, 3);
        assertEq(aliceBalance1After, 10);
        assertEq(aliceBalance2After, 10);
        assertEq(aliceBalance3After, 10);

        vm.stopPrank();
    }

    function testBatchMintToERC1155Recipient() public {
        // check receiver implements the IERC1155Receiver.onERC1155BatchReceived - https://docs.openzeppelin.com/contracts/3.x/api/token/erc1155#IERC1155Receiver-onERC1155BatchReceived-address-address-uint256---uint256---bytes-
    }

    function testBurn() public {
        vm.startPrank(alice);

        // mint Alice 10 tokens of id 1
        token.mint(alice, 1, 10);
        uint aliceBalance = token.balanceOf(alice, 1);
        assertEq(aliceBalance, 10);

        // burn 5 tokens from Alice of id 1
        token.burn(alice, 1, 5);
        uint aliceBalanceAfter = token.balanceOf(alice, 1);
        assertEq(aliceBalanceAfter, 5);

        // burn another 5 tokens from Alice of id 1
        token.burn(alice, 1, 5);
        uint aliceBalanceAfter2 = token.balanceOf(alice, 1);
        assertEq(aliceBalanceAfter2, 0);
        
        vm.stopPrank();
    }

    function testBatchBurn() public {

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
        vm.startPrank(alice);

        // mint Alice 10 tokens of id 1
        token.mint(alice, 1, 10);
        uint aliceBalanceBefore = token.balanceOf(alice, 1);
        uint bobBalanceBefore = token.balanceOf(bob, 1);
        assertEq(aliceBalanceBefore, 10);
        assertEq(bobBalanceBefore, 0);

        // address,address,uint256,uint256,bytes
        token.safeTransferFrom(alice, bob, 1, 10, "");
        uint bobBalanceAfter = token.balanceOf(bob, 1);
        uint aliceBalanceAfter = token.balanceOf(alice, 1);
        assertEq(bobBalanceAfter, 10);
        assertEq(aliceBalanceAfter, 0);

        // testing safeTransferFrom approvals
        // mint alice 10 more tokens and have her set bob as an approved operator
        token.mint(alice, 1, 10);
        token.setApprovalForAll(bob, true);
        vm.stopPrank();

        // setting bob as the function caller, transfer 10 tokens from alice to charlie
        vm.prank(bob);
        token.safeTransferFrom(alice, charlie, 1, 10, "");
        uint charlieBalanceAfter = token.balanceOf(charlie, 1);
        assertEq(charlieBalanceAfter, 10);
    }

    function testSafeTransferFromToERC1155Recipient() public {
        // receiver must implement IERC1155Receiver.onERC1155Received - https://docs.openzeppelin.com/contracts/3.x/api/token/erc1155#IERC1155Receiver-onERC1155Received-address-address-uint256-uint256-bytes-
    }

    function testSafeBatchTransferFromToEOA() public {
        vm.startPrank(alice);

        // mint Alice 10 tokens of id 1
        token.mint(alice, 1, 10);
        uint aliceBalanceBefore = token.balanceOf(alice, 1);
        uint bobBalanceBefore = token.balanceOf(bob, 1);
        assertEq(aliceBalanceBefore, 10);
        assertEq(bobBalanceBefore, 0);

        // mint Alice 10 tokens of id 2
        token.mint(alice, 2, 10);
        uint aliceBalanceBefore2 = token.balanceOf(alice, 2);
        uint bobBalanceBefore2 = token.balanceOf(bob, 1);
        assertEq(aliceBalanceBefore2, 10);
        assertEq(bobBalanceBefore2, 0);

        // transfer 10 tokens of id 1 and 10 tokens of id 2 from alice to bob
        ids.push(1);
        ids.push(2);

        amounts.push(10);
        amounts.push(10);

        token.safeBatchTransferFrom(alice, bob, ids, amounts, "");
        uint bobBalanceAfter1 = token.balanceOf(bob, 1);
        uint aliceBalanceAfter1 = token.balanceOf(alice, 1);
        assertEq(bobBalanceAfter1, 10);
        assertEq(aliceBalanceAfter1, 0);

        uint bobBalanceAfter2 = token.balanceOf(bob, 2);
        uint aliceBalanceAfter2 = token.balanceOf(alice, 2);
        assertEq(bobBalanceAfter2, 10);
        assertEq(aliceBalanceAfter2, 0);

        vm.stopPrank();
    }

    function testSafeBatchTransferFromToERC1155Recipient() public {
        // receiver must implement IERC1155Receiver.onERC1155BatchReceived - https://docs.openzeppelin.com/contracts/3.x/api/token/erc1155#IERC1155Receiver-onERC1155BatchReceived-address-address-uint256---uint256---bytes-
    }

    function testBalanceOfBatch() public {
        vm.startPrank(alice);

        // mint Alice 10 tokens of id 1
        token.mint(alice, 1, 10);
        uint aliceBalanceBefore = token.balanceOf(alice, 1);
        assertEq(aliceBalanceBefore, 10);

        // mint Bob 10 tokens of id 1
        token.mint(bob, 1, 10);
        uint bobBalanceBefore = token.balanceOf(bob, 1);
        assertEq(bobBalanceBefore, 10);

        ids.push(1);
        ids.push(1);

        accounts.push(alice);
        accounts.push(bob);


        uint256[] memory balances = token.balanceOfBatch(accounts, ids);
        assertEq(balances[0], 10);
        assertEq(balances[1], 10);

        vm.stopPrank();
    }

    function testOwner() public {
        address owner = token.owner();
        assertEq(owner, address(yulDeployer));
    }


    // @note test failure case for each function as well?

}