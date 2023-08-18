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

        bytes32 slot = keccak256(abi.encode(alice, keccak256(abi.encode(uint256(1), uint256(1)))));
        bytes32 data = vm.load(address(token), slot);
        console.logBytes32(data);
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

    function testOwner() public {
        address owner = token.owner();
        assertEq(owner, address(yulDeployer));
    }


    // @note test failure case for each function as well?

}