/*
STORAGE LAYOUT:

owner: slot 0
mapping(uint256 id => mapping(address account => uint256)) balances: (slot 1)
  - firstHash = keccak256(id, 1)
  - slot = keccak256(account, firstHash)
mapping(address owner => mapping(address operator => bool)) operatorApprovalsSlot: (slot 2)
  - firstHash = keccak256(owner, 2)
  - slot = keccak256(operator, firstHash)
uri: slot 3
*/


object "ERC1155" {
  // constructor
  // this "code" node is the single executable code of the object. 
  code {
    // store caller as owner in the owner storage slot
    sstore(0, caller())

    // deploy the contract
    datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
    return(0, datasize("Runtime"))
  }

  object "Runtime" {
    // Return the calldata
    code {
      /* --------- DISPATCHER --------- */
      // in most programming languages, it'll evaluate all the case statements, even if one before it is true
      // in yul, it will stop once it finds the first case statemnet that matches
      switch selector()
      // mint(address,uint256,uint256)
      // todo: change this function selector to include the data at the end
      case 0x156e29f6 {
        // decode calldata as value types
        // require(to != address(0))
        // if to address is a smart contract, require that it implements onERC1155Received
        let to := decodeAsAddress(0)
        let id := decodeAsUint(1)
        let value := decodeAsUint(2)

        _mint(to, id, value)
      }

      // mintBatch(address,uint256[],uint256[],bytes)
      // @note ids and values arrays must have the same length
      // @note the first 32 bytes of a dynamic array in the calldata is the length of the array, then followed by the actual values of the elements
      // @note the argument position actually points to the offset in the calldata where the array data starts at
      case 0x1f7fdffa {
        // todo: include the data
        let to := decodeAsAddress(0)
        let idArrayOffset := decodeAsUint(1)
        let amountArrayOffset := decodeAsUint(2)

        _mintBatch(to, idArrayOffset, amountArrayOffset)
      }


      // safeTransferFrom(address,address,uint256,uint256,bytes)
      case 0xf242432a {
        let from := decodeAsAddress(0)
        let to := decodeAsAddress(1)
        let id := decodeAsUint(2)
        let value := decodeAsUint(3)
        let data := decodeAsUint(4)

        _safeTransferFrom(from, to, id, value, data)
      }

      // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)
      case 0x2eb2c2d6 {
        let from := decodeAsAddress(0)
        let to := decodeAsAddress(1)
        let idArrayOffset := decodeAsUint(2)
        let amountArrayOffset := decodeAsUint(3)
        let data := decodeAsUint(4)

        _safeBatchTransferFrom(from, to, idArrayOffset, amountArrayOffset, data)
      }

      // balanceOf(address,uint256)
      case 0x00fdd58e {
        let account := decodeAsAddress(0)
        let id := decodeAsUint(1)
        returnUint(_balanceOf(account, id))
      }

      // balanceOfBatch(address[],uint256[])
      case 0x4e1273f4 {

      }

      // setApprovalForAll(address,bool)
      case 0xa22cb465 {
        let operator := decodeAsAddress(0)
        let isApproved := decodeAsUint(1)

        _setApprovalForAll(caller(), operator, isApproved)
      }

      // isApprovedForAll(address,address)
      case 0xe985e9c5 {
        let tokenOwner := decodeAsAddress(0)
        let operator := decodeAsAddress(1)

        returnUint(_isApprovedForAll(tokenOwner, operator))
      }

      // burn(address,uint256,uint256)
      case 0xf5298aca {

      }

      // burnBatch(address,uint256[],uint256[])
      case 0x6b20c454 {
        
      }

      // owner()
      case 0x8da5cb5b {
        mstore(0, _owner())
        return(0, 0x20)
      }

      default {
        // just revert if no function selector matches
        revert(0, 0)
      }


      /* --------- CALLDATA DECODING --------- */
      /// @dev decode function selector
      function selector() -> s {
        // load calldata from offset 0 and divide to get only first 4 bytes
        s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
      }

      /// @dev proper checks to ensure it is a valid adddress
      function decodeAsAddress(offset) -> v {
        // decode the calldata at the given offset
        v := decodeAsUint(offset)
        // checks whether it is the zero address and reverts if so
        if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
            revert(0, 0)
        }
      }

      /// @dev decode calldata at given offset
      function decodeAsUint(offset) -> v {
          // 4 bytes to skip the function selector
          let pos := add(4, mul(offset, 0x20))
          // check if there is 32 bytes of calldata left to read
          if lt(calldatasize(), add(pos, 0x20)) {
              revert(0, 0)
          }
          // return the value at the specified position in calldata
          v := calldataload(pos)
      }

      function decodeDynamicArrayValueAtOffset(offset) -> v {
        // the offset value comes in as # of bytes. We divide by 32 bytes to get position number
        let positionOffset := div(offset, 0x20)
        v := decodeAsUint(positionOffset)
      }

      /* --------- FUNCTIONS --------- */

      function _owner() -> o {
        o := sload(ownerSlot())
      }

      function _mint(account, id, amount) {
        let offset := _accountBalanceStorageOffset(account, id)
        let prevBalance := sload(offset)
        sstore(offset, add(prevBalance, amount))
        // todo: emit mint event
      }

      function _mintBatch(account, idArrayOffset, amountArrayOffset) {
        // id array and values array lengths must be the same
        let idArrayLength := decodeDynamicArrayValueAtOffset(idArrayOffset)
        let amountArrayLength := decodeDynamicArrayValueAtOffset(amountArrayOffset)
        if iszero(eq(idArrayLength, amountArrayLength)) {
          revert(0, 0)
        }
        
        // for how many ids and values there are, call mint that many times
        for { let i := 0} lt(i, idArrayLength) { i := add(i, 1) } { 
          // add 1 because first value is the length value
          let currentIdPosition := add(add(div(idArrayOffset, 0x20), 1), i)
          let currentIdElement := decodeAsUint(currentIdPosition)

          // add 1 because first value is the length value
          let currentAmountPosition := add(add(div(amountArrayOffset, 0x20), 1), i)
          let currentAmountElement := decodeAsUint(currentAmountPosition)
          
          // mint user the amount of tokens for the given id
          _mint(account, currentIdElement, currentAmountElement)
        }
      }

      function _balanceOf(account, id) -> amount {
        let offset := _accountBalanceStorageOffset(account, id)
        amount := sload(offset)
      }

      /// @dev sets approval for all
      function _setApprovalForAll(tokenOwner, operator, isApproved) {
        // get offset of the isApprovedForAll mapping
        let offset := _approvalForAllOffset(tokenOwner, operator)
        // set the value to true or false
        sstore(offset, isApproved)
      }

      function _isApprovedForAll(tokenOwner, operator) -> isApproved {
        let offset := _approvalForAllOffset(tokenOwner, operator)
        isApproved := sload(offset)
      }

      function _safeTransferFrom(from, to, id, value, data) {
        // check if from == msg.sender OR if caller is an approved operator
        // todo: clean up this nested if statement check
        let isApprovedOperator := _isApprovedForAll(from, caller())
        if and(iszero(eq(caller(), from)), iszero(isApprovedOperator))  {
          revert(0, 0)
        }
        // check that the from address has enough balance to make the transfer
        let fromBalance := _balanceOf(from, id)
        if lt(fromBalance, value) {
          revert(0,0)
        }
        // if above conditions pass, then we can update the balances
        // add "value" to the balance of "to" address and subtract "value" from the balance of the "from" address
        let prevToBalanceOffset := _accountBalanceStorageOffset(to, id)
        let prevToBalance := sload(prevToBalanceOffset)

        let prevFromBalanceOffset := _accountBalanceStorageOffset(from, id)
        let prevFromBalance := sload(prevFromBalanceOffset)

        sstore(prevToBalanceOffset, add(prevToBalance, value))  // todo: check for integer overflow here??
        sstore(prevFromBalanceOffset, sub(prevFromBalance, value))  // todo: check for integer underflow here??

        // todo: implement onERC1155Received acceptance check
        
      }

      function _safeBatchTransferFrom(from, to, idArrayOffset, amountArrayOffset, data) {
        // id array and values array lengths must be the same
        let idArrayLength := decodeDynamicArrayValueAtOffset(idArrayOffset)
        let amountArrayLength := decodeDynamicArrayValueAtOffset(amountArrayOffset)
        if iszero(eq(idArrayLength, amountArrayLength)) {
          revert(0, 0)
        }

        // for how many ids and values there are, call safeTransferFrom that many times
        // safeTransferFrom has all the balance and opperator checks needed
        for {let i := 0} lt(i, idArrayLength) {i := add(i, 1)} {
          // add 1 because first value is the length value
          let currentIdPosition := add(add(div(idArrayOffset, 0x20), 1), i)
          let currentIdElement := decodeAsUint(currentIdPosition)

          // add 1 because first value is the length value
          let currentAmountPosition := add(add(div(amountArrayOffset, 0x20), 1), i)
          let currentAmountElement := decodeAsUint(currentAmountPosition)

          _safeTransferFrom(from, to, currentIdElement, currentAmountElement, data)
        }
      }

      /* --------- STORAGE ACCESS --------- */
      function ownerSlot() -> p {
        p := 0
      }

      function balancesSlot() -> p {
        p := 1
      }

      function _operatorApprovalsSlot() -> p {
        p := 2
      }

        function uriSlot() -> p {
        p := 3
      }
      

      /// @dev get the offset for the given account's balance => balances[id][account]
      function _accountBalanceStorageOffset(account, id) -> offset {
        // firstHash = keccak256(id, balancesSlot)
        // slot = keccak256(account, firstHash)
        // store the first hash in memory location 0x60 to be used for second hash
        // store id, balances slot, and account to hash later on
        mstore(0, id)
        mstore(0x20, balancesSlot())
        mstore(0x40, account)
        mstore(0x60, keccak256(0, 0x40))
        offset := keccak256(0x40, 0x80)
      }

      /// @dev get the offset for the given operator's account approval
      function _approvalForAllOffset(tokenOwner, operator) -> offset {
        // firstHash = keccak256(owner, operatorApprovalsSlot) 
        // storage slot = keccak256(operator, firstHash)
        mstore(0, tokenOwner)
        mstore(0x20, _operatorApprovalsSlot())
        mstore(0x40, operator)
        mstore(0x60, keccak256(0, 0x40))
        offset := keccak256(0x40, 0x80)
      }


      /* --------- EVENTS --------- */



      /* --------- HELPERS --------- */
      /// @dev used to return the value that you pass into the function
      function returnUint(v) {
        // store value into memory first and then return it
        mstore(0, v)
        return(0, 0x20)
      }

      /// @dev used to return the value 1, which represents true
      function returnTrue() {
        returnUint(1)
      }


      /* --------- LOGGING HELPERS --------- */

       function revertWithReason(reason, reasonLength) {
          let ptr := 0x00 //since we are going to abort, can use memory at 0x00
          mstore(ptr, shl(0xe0,0x08c379a)) // Selector for method Error(string)
          mstore(add(ptr, 0x04), 0x20) // String offset
          mstore(add(ptr, 0x24), reasonLength) // Revert reason length
          mstore(add(ptr, 0x44), reason)
          revert(ptr, 0x64)
        }

        /// @notice emulates the solidity require statement
        /// @dev eg, requireWithMessage(iszero(callvalue()),"ether not accepted", 18)
        function requireWithMessage(condition, reason, reasonLength) {
            if iszero(condition) { 
                revertWithReason(reason, reasonLength)
            }
        }

        /// @notice just logs out a string
        /// @dev restricted to a string literal
        function logString(memPtr, message, lengthOfMessage) {
            mstore(memPtr, shl(0xe0,0x0bb563d6))        //selector for function logString(string memory p0) 
            mstore(add(memPtr, 0x04), 0x20)             //offset
            mstore(add(memPtr, 0x24), lengthOfMessage)  //length
            mstore(add(memPtr, 0x44), message)          //data
            pop(staticcall(gas(), consoleContractAddress(), memPtr, 0x64, 0x00, 0x00))
        }

        /// @notice writes out one word from calldata at the given offset
        /// @param memPtr where the call to the logging contract should be prepared
        function logCalldataByOffset(memPtr, offset) {
            mstore(memPtr, shl(0xe0, 0xe17bf956))   //selector for function logBytes(bytes memory p0)
            mstore(add(memPtr, 0x04), 0x20)
            mstore(add(memPtr, 0x24), 0x20)
            calldatacopy(add(memPtr, 0x44), offset, 0x20)
            pop(staticcall(gas(), consoleContractAddress(), memPtr, 0x64, 0x00, 0x00))
        }

        /// @notice writes out all of call data. skipping the selector aligns the output
        /// for good readability
        /// @param memPtr where the call is prepared
        /// @param skipSelector whether or not to print the method selector
        function logCalldata(memPtr, skipSelector) {
            //the "request header" remains the same, we keep
            //sending 32 bytes to the console contract
            mstore(memPtr, shl(0xe0, 0xe17bf956))   //selector for function logBytes(bytes memory p0)
            mstore(add(memPtr, 0x04), 0x20)
            mstore(add(memPtr, 0x24), 0x20)

            let dataLength := calldatasize()
            let calldataOffset := 0x00
            if skipSelector {
                dataLength := sub(dataLength, 4)
            }
            let dataLengthRoundedToWord := roundToWord(dataLength)
            
            for { let i := 0 } lt(i, dataLengthRoundedToWord) { i:= add(i, 1) } {
                calldataOffset := mul(i, 0x20)
                if skipSelector {
                    calldataOffset := add(calldataOffset,0x04)
                }    
                calldatacopy(add(memPtr, 0x44), calldataOffset, 0x20)
                pop(staticcall(gas(), consoleContractAddress(), memPtr, 0x64, 0x00, 0x00))
            }
        }

        function logAddress(memPtr, addressValue) {
            mstore(memPtr, shl(0xe0, 0xe17bf956))   //selector for function logBytes(bytes memory p0)
            mstore(add(memPtr, 0x04), 0x20)
            mstore(add(memPtr, 0x24), 0x20)
            mstore(add(memPtr, 0x44), addressValue)
            pop(staticcall(gas(), consoleContractAddress(), memPtr, 0x64, 0x00, 0x00))
        }

        /// @notice writes out a desired snapshot of memory
        /// @dev whole word (ie. 32 bytes) is written out, so if the length is not an even number
        /// the difference is padded with 0s
        function logMemory(memPtr, startingPointInMemory, length) {
            mstore(memPtr, shl(0xe0, 0xe17bf956))   //selector for function logBytes(bytes memory p0)
            mstore(add(memPtr, 0x04), 0x20)
            mstore(add(memPtr, 0x24), length)
            let dataLengthRoundedToWord := roundToWord(length)
            let memOffset := 0x00
            for { let i := 0 } lt(i, dataLengthRoundedToWord) { i:= add(i, 1) } {
                memOffset := mul(i, 0x20)
                mstore(add(memPtr, 0x44), mload(add(startingPointInMemory,memOffset)))
                pop(staticcall(gas(), consoleContractAddress(), memPtr, 0x64, 0x00, 0x00))
            }                
        }
        
        /// @notice simply prints the number out
        /// @param memPtr
        /// @param _number this is any 32 byte value
        function logNumber(memPtr, _number) {
            mstore(memPtr, shl(0xe0,0x9905b744))    //select for function logUint(uint256 p0)
            mstore(add(memPtr, 0x04), _number)
            pop(staticcall(gas(), consoleContractAddress(), memPtr, 0x24, 0x00, 0x00))
        }

        /* ---------- utility functions ---------- */

        function require(condition) {
            if iszero(condition) { revert(0, 0) }
        }

        function roundToWord(length) -> numberOfWords {
            numberOfWords := div(length, 0x20)
            if gt(mod(length,0x20),0) {
                numberOfWords := add(numberOfWords, 1)
            }
        }

        function consoleContractAddress() -> a {
            a := 0x000000000000000000636F6e736F6c652e6c6f67
        }

    }
  }
}