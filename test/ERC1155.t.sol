// SPDX-License-Identifier: MIT
// TODO: change floating pragma
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "./lib/YulDeployer.sol";
import "./lib/IERC1155.sol";
import "./lib/ERC1155Reciever.sol";
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
    ERC1155Reciever erc1155reciever = new ERC1155Reciever();

    IERC1155 token;
    address alice = address(123);
    address bob = address(456);
    address charlie = address(789);

    uint256[] ids;
    uint256[] amounts;
    address[] accounts;

    // events testing
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function setUp() public {
        token = IERC1155(yulDeployer.deployContract("ERC1155"));
    }

    function testMintToEOA() public {
        vm.startPrank(alice);

        // test emitting event
        vm.expectEmit(true, true, true, true);
        // We emit the event we expect to see
        emit TransferSingle(alice, address(0), alice, 1, 10);

        // mint Alice 10 tokens of id 1
        token.mint(alice, 1, 10, "");
        uint aliceBalance = token.balanceOf(alice, 1);
        assertEq(aliceBalance, 10);
        
        vm.stopPrank();
    }


    function testMintToERC1155Recipient() public {
        // check that receiver implements the IERC1155Receiver.onERC1155Received - https://docs.openzeppelin.com/contracts/3.x/api/token/erc1155#IERC1155Receiver-onERC1155Received-address-address-uint256-uint256-bytes-
        address reciever = address(erc1155reciever);
        vm.startPrank(address(reciever));

        // mint smart contract 10 tokens of id 1
        token.mint(reciever, 1, 10, "data");
        uint recieverBalance = token.balanceOf(reciever, 1);
        assertEq(recieverBalance, 10);
        
        vm.stopPrank();
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

        // make sure Alice has no tokens to start
        uint aliceBalance1Before = token.balanceOf(alice, 1);
        uint aliceBalance2Before = token.balanceOf(alice, 2);
        uint aliceBalance3Before = token.balanceOf(alice, 3);
        assertEq(aliceBalance1Before, 0);
        assertEq(aliceBalance2Before, 0);
        assertEq(aliceBalance3Before, 0);

        // batch mint
        token.mintBatch(alice, ids, amounts, "");

        // check token balances afterwards
        uint aliceBalance1After = token.balanceOf(alice, 1);
        uint aliceBalance2After = token.balanceOf(alice, 2);
        uint aliceBalance3After = token.balanceOf(alice, 3);
        assertEq(aliceBalance1After, 10);
        assertEq(aliceBalance2After, 10);
        assertEq(aliceBalance3After, 10);

        vm.stopPrank();
    }

    function testBatchMintToERC1155Recipient() public {
        address reciever = address(erc1155reciever);
        vm.startPrank(address(reciever));

        // create batch ids to mint
        ids.push(1);
        ids.push(2);
        ids.push(3);

        // create batch amounts to mint
        amounts.push(10);
        amounts.push(10);
        amounts.push(10);

        // make sure receiver doesn't have any tokens to start
        uint reciever1Before = token.balanceOf(reciever, 1);
        uint reciever2Before = token.balanceOf(reciever, 2);
        uint reciever3Before = token.balanceOf(reciever, 3);
        assertEq(reciever1Before, 0);
        assertEq(reciever2Before, 0);
        assertEq(reciever3Before, 0);

        // batch mint
        token.mintBatch(reciever, ids, amounts, "");

        // check token balances afterwards
        uint recieverBalance1After = token.balanceOf(reciever, 1);
        uint recieverBalance2After = token.balanceOf(reciever, 2);
        uint recieverBalance3After = token.balanceOf(reciever, 3);
        assertEq(recieverBalance1After, 10);
        assertEq(recieverBalance2After, 10);
        assertEq(recieverBalance3After, 10);

        vm.stopPrank();
    }

    function testBurn() public {
        vm.startPrank(alice);

        // mint Alice 10 tokens of id 1
        token.mint(alice, 1, 10, "");
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
        vm.startPrank(alice);
        // create batch ids to mint
        ids.push(1);
        ids.push(2);
        ids.push(3);

        // create batch amounts to mint
        amounts.push(10);
        amounts.push(10);
        amounts.push(10);

        // make sure Alice doesn't have any tokens to start
        uint aliceBalance1Before = token.balanceOf(alice, 1);
        uint aliceBalance2Before = token.balanceOf(alice, 2);
        uint aliceBalance3Before = token.balanceOf(alice, 3);
        assertEq(aliceBalance1Before, 0);
        assertEq(aliceBalance2Before, 0);
        assertEq(aliceBalance3Before, 0);

        // batch mint
        token.mintBatch(alice, ids, amounts, "");

        // check balances afterwards
        uint aliceBalance1After = token.balanceOf(alice, 1);
        uint aliceBalance2After = token.balanceOf(alice, 2);
        uint aliceBalance3After = token.balanceOf(alice, 3);
        assertEq(aliceBalance1After, 10);
        assertEq(aliceBalance2After, 10);
        assertEq(aliceBalance3After, 10);

        // now burn batch
        token.burnBatch(alice, ids, amounts);

        // check balances afterwards
        uint aliceBalance1AfterBurn = token.balanceOf(alice, 1);
        uint aliceBalance2AfterBurn = token.balanceOf(alice, 2);
        uint aliceBalance3AfterBurn = token.balanceOf(alice, 3);
        assertEq(aliceBalance1AfterBurn, 0);
        assertEq(aliceBalance2AfterBurn, 0);
        assertEq(aliceBalance3AfterBurn, 0);
    }

    // @note there is no function for "approve". It's only approve all
    function testApproveAll() public {
        vm.startPrank(alice);

        // test emitting event
        vm.expectEmit(true, true, true, true);
        // We emit the event we expect to see
        emit ApprovalForAll(alice, bob, true);

        // set Bob as an approved operator for Alice
        token.setApprovalForAll(bob, true);
        bool isApproved = token.isApprovedForAll(alice, bob);
        assertTrue(isApproved);

        vm.stopPrank();
    }

    function testSafeTransferFromToEOA() public {
        vm.startPrank(alice);

        // mint Alice 10 tokens of id 1
        token.mint(alice, 1, 10, "");
        uint aliceBalanceBefore = token.balanceOf(alice, 1);
        uint bobBalanceBefore = token.balanceOf(bob, 1);
        assertEq(aliceBalanceBefore, 10);
        assertEq(bobBalanceBefore, 0);

        // test emitting event
        vm.expectEmit(true, true, true, true);
        // We emit the event we expect to see
        emit TransferSingle(alice, alice, bob, 1, 10);

        // address,address,uint256,uint256,bytes
        token.safeTransferFrom(alice, bob, 1, 10, "");
        uint bobBalanceAfter = token.balanceOf(bob, 1);
        uint aliceBalanceAfter = token.balanceOf(alice, 1);
        assertEq(bobBalanceAfter, 10);
        assertEq(aliceBalanceAfter, 0);

        // testing safeTransferFrom approvals
        // mint Alice 10 more tokens and have her set Bob as an approved operator
        token.mint(alice, 1, 10, "");
        token.setApprovalForAll(bob, true);
        vm.stopPrank();

        // setting Bob as the function caller, transfer 10 tokens from Alice to Charlie
        vm.prank(bob);
        token.safeTransferFrom(alice, charlie, 1, 10, "");
        uint charlieBalanceAfter = token.balanceOf(charlie, 1);
        assertEq(charlieBalanceAfter, 10);

    }

    function testSafeTransferFromToERC1155Recipient() public {
        // receiver must implement IERC1155Receiver.onERC1155Received - https://docs.openzeppelin.com/contracts/3.x/api/token/erc1155#IERC1155Receiver-onERC1155Received-address-address-uint256-uint256-bytes-
        vm.startPrank(alice);

        // mint Alice 10 tokens of id 1
        token.mint(alice, 1, 10, "");
        uint aliceBalanceBefore = token.balanceOf(alice, 1);
        uint bobBalanceBefore = token.balanceOf(bob, 1);
        assertEq(aliceBalanceBefore, 10);
        assertEq(bobBalanceBefore, 0);

        // safe transfer from Alice To Bob
        token.safeTransferFrom(alice, bob, 1, 10, "");
        uint bobBalanceAfter = token.balanceOf(bob, 1);
        uint aliceBalanceAfter = token.balanceOf(alice, 1);
        assertEq(bobBalanceAfter, 10);
        assertEq(aliceBalanceAfter, 0);

        // testing safeTransferFrom approvals
        // mint alice 10 more tokens and have her set bob as an approved operator
        token.mint(alice, 1, 10, "");
        token.setApprovalForAll(bob, true);
        vm.stopPrank();

        // setting Bob as the function caller, transfer 10 tokens from Alice to smart contract receiver
        vm.prank(bob);
        address reciever = address(erc1155reciever);
        token.safeTransferFrom(alice, reciever, 1, 10, "");
        uint recieverBalanceAfter = token.balanceOf(reciever, 1);
        assertEq(recieverBalanceAfter, 10);
    }

    function testSafeBatchTransferFromToEOA() public {
        vm.startPrank(alice);

        // mint Alice 10 tokens of id 1
        token.mint(alice, 1, 10, "");
        uint aliceBalanceBefore = token.balanceOf(alice, 1);
        uint bobBalanceBefore = token.balanceOf(bob, 1);
        assertEq(aliceBalanceBefore, 10);
        assertEq(bobBalanceBefore, 0);

        // mint Alice 10 tokens of id 2
        token.mint(alice, 2, 10, "");
        uint aliceBalanceBefore2 = token.balanceOf(alice, 2);
        uint bobBalanceBefore2 = token.balanceOf(bob, 1);
        assertEq(aliceBalanceBefore2, 10);
        assertEq(bobBalanceBefore2, 0);

        // transfer 10 tokens of id 1 and 10 tokens of id 2 from alice to bob
        ids.push(1);
        ids.push(2);

        amounts.push(10);
        amounts.push(10);

        // test emitting event
        vm.expectEmit(true, true, true, true);
        // We emit the event we expect to see
        emit TransferBatch(alice, alice, bob, ids, amounts);


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
        vm.startPrank(alice);
        address reciever = address(erc1155reciever);

        // mint Alice 10 tokens of id 1
        token.mint(alice, 1, 10, "");
        uint aliceBalanceBefore = token.balanceOf(alice, 1);
        uint bobBalanceBefore = token.balanceOf(bob, 1);
        assertEq(aliceBalanceBefore, 10);
        assertEq(bobBalanceBefore, 0);

        // mint Alice 10 tokens of id 2
        token.mint(alice, 2, 10, "");
        uint aliceBalanceBefore2 = token.balanceOf(alice, 2);
        uint recieverBalanceBefore2 = token.balanceOf(reciever, 1);
        assertEq(aliceBalanceBefore2, 10);
        assertEq(recieverBalanceBefore2, 0);

        // transfer 10 tokens of id 1 and 10 tokens of id 2 from Alice to smart contract receiver
        ids.push(1);
        ids.push(2);

        amounts.push(10);
        amounts.push(10);

        token.safeBatchTransferFrom(alice, reciever, ids, amounts, "");
        uint recieverBalanceAfter1 = token.balanceOf(reciever, 1);
        uint aliceBalanceAfter1 = token.balanceOf(alice, 1);
        assertEq(recieverBalanceAfter1, 10);
        assertEq(aliceBalanceAfter1, 0);

        uint recieverBalanceAfter2 = token.balanceOf(reciever, 2);
        uint aliceBalanceAfter2 = token.balanceOf(alice, 2);
        assertEq(recieverBalanceAfter2, 10);
        assertEq(aliceBalanceAfter2, 0);

        vm.stopPrank();
    }

    function testBalanceOfBatch() public {
        vm.startPrank(alice);

        // mint Alice 10 tokens of id 1
        token.mint(alice, 1, 10, "");
        uint aliceBalanceBefore = token.balanceOf(alice, 1);
        assertEq(aliceBalanceBefore, 10);

        // mint Bob 10 tokens of id 1
        token.mint(bob, 1, 10, "");
        uint bobBalanceBefore = token.balanceOf(bob, 1);
        assertEq(bobBalanceBefore, 10);

        ids.push(1);
        ids.push(1);

        accounts.push(alice);
        accounts.push(bob);

        // check balances
        uint256[] memory balances = token.balanceOfBatch(accounts, ids);
        assertEq(balances[0], 10);
        assertEq(balances[1], 10);

        vm.stopPrank();
    }

    function testOwner() public {
        address owner = token.owner();
        assertEq(owner, address(yulDeployer));
    }
}