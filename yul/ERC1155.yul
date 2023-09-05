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
      // mint(address,uint256,uint256,bytes)
      /// @param to - the address to mint the tokens to
      /// @param id - the token id to mint
      /// @param amount - the amount of tokens to mint
      /// @param data - data for transfer hook, not implemented
      case 0x731133e9 {
        // decode calldata
        let to := decodeAsAddress(0)
        let id := decodeAsUint(1)
        let amount := decodeAsUint(2)
        let dataOffset := decodeAsUint(3)

        // mint tokens
        _mint(to, id, amount)

        // only call if receiver is a smart contract
        // check that the "to" address receiving the tokens has onERC1155Received implemented
        if gt(extcodesize(to), 0) {
          _erc1155RecievedCheck(caller(), 0, to, id, amount, dataOffset)
        }
      }

      // mintBatch(address,uint256[],uint256[],bytes)
      /// @note id and amount arrays must have the same length
      /// @param to - the address to mint the tokens to
      /// @param ids - the array of token ids to mint
      /// @param amounts - the array of the amount of tokens to mint
      case 0x1f7fdffa {
        // decode calldata
        // the first 32 bytes of a dynamic array in the calldata is the length of the array, then followed by the actual values of the elements
        // the argument position actually points to the offset in the calldata where the array data starts at
        let to := decodeAsAddress(0)
        let idArrayOffset := decodeAsUint(1)
        let amountArrayOffset := decodeAsUint(2)
        let dataOffset := decodeAsUint(3)

        // batch mint tokens
        _mintBatch(to, idArrayOffset, amountArrayOffset, dataOffset)

        // todo implement batch acceptance check
        // only call if receiver is a smart contract
        // if gt(extcodesize(to), 0) {
        //   _erc1155BatchRecievedCheck(caller(), 0, to, idArrayOffset, amountArrayOffset, dataOffset)
        // }
      }

      // safeTransferFrom(address,address,uint256,uint256,bytes)
      /// @param from - address to transfer tokens from (sender)
      /// @param to - address to transfer tokens to (receiver)
      /// @param id - token id to transfer
      /// @param amount - amount of tokens to transfer
      /// @param data - data for transfer hook - not implemented
      case 0xf242432a {
        let from := decodeAsAddress(0)
        let to := decodeAsAddress(1)
        let id := decodeAsUint(2)
        let amount := decodeAsUint(3)
        let dataOffset := decodeAsUint(4)

        // transfer tokens
        _safeTransferFrom(from, to, id, amount)

        // only call if reciever is a smart contract
        // check that the "to" address receiving the tokens has onERC1155Received implemented
        if gt(extcodesize(to), 0) {
          _erc1155RecievedCheck(caller(), from, to, id, amount, dataOffset)
        }
      }

      // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)
      /// @param from - address to transfer tokens from (sender)
      /// @param to - address to transfer tokens to (receiver)
      /// @param ids - array of token ids to transfer
      /// @param amounts - array of the amount of tokens to transfer
      /// @param data - data for transfer hook - not implemented
      case 0x2eb2c2d6 {
        // decode calldata
        let from := decodeAsAddress(0)
        let to := decodeAsAddress(1)
        let idArrayOffset := decodeAsUint(2)
        let amountArrayOffset := decodeAsUint(3)
        let dataOffset := decodeAsUint(4)

        _safeBatchTransferFrom(from, to, idArrayOffset, amountArrayOffset, dataOffset)

        // todo implement batch acceptance check
      }

      // balanceOf(address,uint256)
      /// @param account - address to get the balance of
      /// @param id - the token id to get the balance of
      case 0x00fdd58e {
        let account := decodeAsAddress(0)
        let id := decodeAsUint(1)
        returnUint(_balanceOf(account, id))
      }

      // balanceOfBatch(address[],uint256[])
      /// @param accounts - array of accounts to get the balance of
      /// @param ids - array of token ids to get the balance of
      case 0x4e1273f4 {
        let accountArrayOffset := decodeAsUint(0)
        let idArrayOffset := decodeAsUint(1)

        _balanceOfBatch(accountArrayOffset, idArrayOffset)
      }

      // setApprovalForAll(address,bool)
      /// @param operator - address to set approval as an operator for
      /// @param isApproved - whether the given address is approved as an operator for the function caller
      case 0xa22cb465 {
        let operator := decodeAsAddress(0)
        let isApproved := decodeAsUint(1)

        _setApprovalForAll(caller(), operator, isApproved)
      }

      // isApprovedForAll(address,address)
      /// @param tokenOwner - address of the owner of the token
      /// @param operator - address of the operator on behalf of the given token owner
      case 0xe985e9c5 {
        let tokenOwner := decodeAsAddress(0)
        let operator := decodeAsAddress(1)

        returnUint(_isApprovedForAll(tokenOwner, operator))
      }

      // burn(address,uint256,uint256)
      /// @param from - address to burn tokens
      /// @param id - token id to burn
      /// @param amount - amount of tokens to burn
      case 0xf5298aca {
        // require that from address is either the token owner or approved operator
        let from := decodeAsAddress(0)
        let id := decodeAsUint(1)
        let amount := decodeAsUint(2)

        _burn(from, id, amount)
      }

      // burnBatch(address,uint256[],uint256[])
      /// @param from - address to burn tokens
      /// @param ids - array of token ids to burn
      /// @param amounts - array of the amount of tokens to burn
      case 0x6b20c454 {
        // require that the from address is either the token owner or approved operator
        let from := decodeAsAddress(0)
        let idArrayOffset := decodeAsUint(1)
        let amountArrayOffset := decodeAsUint(2)
      }

      // owner()
      /// @return - returns the address owner of the contract
      case 0x8da5cb5b {
        mstore(0, _owner())
        return(0, 0x20)
      }

      default {
        // revert if no function selector matches
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
        // checks whether it is a valid address and reverts if so
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

      function decodeDynamicValueAtOffset(offset) -> v {
        // the offset value comes in as # of bytes. We divide by 32 bytes to get position number
        let positionOffset := div(offset, 0x20)
        v := decodeAsUint(positionOffset)
      }

      /* --------- INTERNAL FUNCTIONS --------- */

      /// @return the address of the owner of the contract
      function _owner() -> o {
        o := sload(ownerSlot())
      }

      /// @dev mints the account the amount of tokens for token id
      function _mint(account, id, amount) {
        let offset := _accountBalanceStorageOffset(account, id)
        let prevBalance := sload(offset)
        sstore(offset, add(prevBalance, amount))
        // todo: emit mint event
      }

      /// @dev 
      function _mintBatch(account, idArrayOffset, amountArrayOffset, dataOffset) {
        // id array and values array lengths must be the same
        let idArrayLength := decodeDynamicValueAtOffset(idArrayOffset)
        let amountArrayLength := decodeDynamicValueAtOffset(amountArrayOffset)
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

      /// @dev returns token balance for given address and token id
      function _balanceOf(account, id) -> amount {
        let offset := _accountBalanceStorageOffset(account, id)
        amount := sload(offset)
      }

      function _balanceOfBatch(accountArrayOffset, idArrayOffset) {
        // account and id array must be the same length
        let accountArrayLength := decodeDynamicValueAtOffset(accountArrayOffset)
        let idArrayLength := decodeDynamicValueAtOffset(idArrayOffset)
        if iszero(eq(accountArrayLength, idArrayLength)) {
          revert(0, 0)
        }

        // initialize starting memory pointer position at 0x80
        let memoryPointer := 0x80

        // this is the offset to where in memory the start of the array will be
        // first value will be the length of the array
        mstore(memoryPointer, 0x20)
        memoryPointer := add(memoryPointer, 0x20)

        // store the array length first
        // need to follow the abi encoding for arrays, or solidty will throw errors when trying to decode it
        mstore(memoryPointer, accountArrayLength)
        memoryPointer := add(memoryPointer, 0x20)

        for { let i := 0 } lt(i, accountArrayLength) { i := add(i, 1) } {
          // get current address
          // add 1 because the first value is the length value
          let currentAccountPosition := add(add(div(accountArrayOffset, 0x20), 1), i)
          let currentAccountElement := decodeAsUint(currentAccountPosition)

          // get current id
          // add 1 because the first value is the length value
          let currentIdPosition := add(add(div(idArrayOffset, 0x20), 1), i)
          let currentIdElement := decodeAsUint(currentIdPosition)

          // get token balance account for given id
          let currentBalance := _balanceOf(currentAccountElement, currentIdElement)

          // store the account balance at the current memory pointer slot
          mstore(memoryPointer, currentBalance)
          memoryPointer := add(memoryPointer, 0x20) // increment memory pointer
        }
        
        // memory pointer starts at 0x80
        // return data starting at position 0x80 with size to where memory pointer currently is at minus 0x80
        return(0x80, sub(memoryPointer, 0x80))
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

      function _safeTransferFrom(from, to, id, amount) {
        // check if from == msg.sender OR if msg.sender is an approved operator
        let isApprovedOperator := _isApprovedForAll(from, caller())
        if and(iszero(eq(caller(), from)), iszero(isApprovedOperator))  {
          revert(0, 0)
        }
        // check that the from address has enough balance to make the transfer
        let fromBalance := _balanceOf(from, id)
        if lt(fromBalance, amount) {
          revert(0,0)
        }
        // if above conditions pass, then we can update the balances
        // add "value" to the balance of "to" address and subtract "value" from the balance of the "from" address
        let prevToBalanceOffset := _accountBalanceStorageOffset(to, id)
        let prevToBalance := sload(prevToBalanceOffset)

        let prevFromBalanceOffset := _accountBalanceStorageOffset(from, id)
        let prevFromBalance := sload(prevFromBalanceOffset)

        sstore(prevToBalanceOffset, add(prevToBalance, amount))  // todo: check for integer overflow here??
        sstore(prevFromBalanceOffset, sub(prevFromBalance, amount))  // todo: check for integer underflow here??
      }

      function _safeBatchTransferFrom(from, to, idArrayOffset, amountArrayOffset, dataOffset) {
        // id array and amount array lengths must be the same
        let idArrayLength := decodeDynamicValueAtOffset(idArrayOffset)
        let amountArrayLength := decodeDynamicValueAtOffset(amountArrayOffset)
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

          _safeTransferFrom(from, to, currentIdElement, currentAmountElement)
        }
      }

      function _burn(from, id, amount) {
        // check if from == msg.sender OR if msg.sender is an approved operator
        let isApprovedOperator := _isApprovedForAll(from, caller())
        if and(iszero(eq(caller(), from)), iszero(isApprovedOperator))  {
          revert(0, 0)
        }

        // check that the from address has enough balance to burn tokens
        let prevBalance := _balanceOf(from, id)
        if lt(prevBalance, amount) {
          revert(0,0)
        }

        // transfer to 0 address to burn tokens
        _safeTransferFrom(from, 0, id, amount)
        // todo: emit burn event
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
        offset := keccak256(0x40, 0x40) // takes starting position and then how many bytes from there you want to hash
      }

      /// @dev get the offset for the given operator's account approval
      function _approvalForAllOffset(tokenOwner, operator) -> offset {
        // firstHash = keccak256(owner, operatorApprovalsSlot) 
        // storage slot = keccak256(operator, firstHash)
        mstore(0, tokenOwner)
        mstore(0x20, _operatorApprovalsSlot())
        mstore(0x40, operator)
        mstore(0x60, keccak256(0, 0x40))
        offset := keccak256(0x40, 0x40) // takes starting position and then how many bytes from there you want to hash
      }


      /* --------- EVENTS --------- */
      // event signature hash is just the keccack256 has of the event signature
    

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

      /// @dev safe add to check for overflow
      function safeAdd(a, b) -> r {
        r := add(a, b)
        if or(lt(r, a), lt(r, b)) { revert(0, 0) }
      }

      function copyDataToMemory(memoryPointer, dataOffset) -> updatedMemoryPointer {
        // get where the length offset of the bytes data is from the calldata
        let dataLengthOffset := add(dataOffset, 4)
        // use the offset to load the actual length of the bytes data
        let dataLength := calldataload(dataLengthOffset)

        // get total length of the bytes data to copy
        let totalLength := add(0x20, dataLength) // add 32 bytes to also store the length of the data
        let remainder := mod(totalLength, 0x20)

        if remainder {
          // need to pad it out to the right so that it's in increments of 32 bytes
          totalLength := add(totalLength, sub(0x20, remainder))
        }

        // copy bytes data from calldata to memory
        calldatacopy(memoryPointer, dataLengthOffset, totalLength)

        // update memory pointer
        updatedMemoryPointer := add(memoryPointer, totalLength)
      }

      function copyArrayToMemory(memoryPointer, arrayOffset) -> updatedMemoryPointer {
          let arrayLengthOffset := add(arrayOffset, 4)
          let arrayLength := calldataload(arrayLengthOffset)
          let totalLength := add(0x20, mul(arrayLength, 0x20)) // add 32 bytes to store the length of the array

          calldatacopy(memoryPointer, arrayLengthOffset, totalLength)

          updatedMemoryPointer := add(memoryPointer, totalLength)
      }

      ///@dev must return if it's a smart contract
      function _erc1155RecievedCheck(operator, from, to, id, amount, dataOffset) {
        let onERC1155Selector := 0xf23a6e6100000000000000000000000000000000000000000000000000000000
        let memoryPointer := 0x80

        // load all your arguments to make the call
        mstore(memoryPointer, onERC1155Selector)
        mstore(add(memoryPointer, 0x04), operator)
        mstore(add(memoryPointer, 0x24), from)
        mstore(add(memoryPointer, 0x44), id)
        mstore(add(memoryPointer, 0x64), amount)
        mstore(add(memoryPointer, 0x84), 0xa0) // data offset starts at position 5 (160 bytes offset)

        // copy the data bytes to memory to be used as argument for the externall call()
        let endMemoryPointer := copyDataToMemory(add(memoryPointer, 0xa4), dataOffset)

        // call(g, a, v, in, insize, out, outsize)
        // store result of call into location 0 in memory
        let success := call(gas(), to, 0, 0x80, sub(endMemoryPointer, 0x80), 0x00, 0x20)
        let returnData := mload(0)

        // revert if the call does not return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
        if iszero(eq(returnData, onERC1155Selector)) {
          revert(0,0)
        }
      }

      /// @dev must return onERC1155BatchReceived(address,address,uint256[],uint256[],bytes) if it's a smart contract
      function _erc1155BatchRecievedCheck(operator, from, to, idOffset, amountOffset, dataOffset) {
        // onERC1155BatchReceived(address,address,uint256[],uint256[],bytes) => 0xbc197c81
        let onERC1155BatchSelector := 0xbc197c8100000000000000000000000000000000000000000000000000000000
        let memoryPointer := 0x80

        // load all your arguments to make the call
        mstore(memoryPointer, onERC1155BatchSelector)
        mstore(add(memoryPointer, 0x04), operator)
        mstore(add(memoryPointer, 0x24), from)
        mstore(add(memoryPointer, 0x44), 0x40) // idOffset starts at 96 (position 3)
        mstore(add(memoryPointer, 0x64), 0x60)  // amountOffset starts at 128 (position 4)
        mstore(add(memoryPointer, 0x84), 0x80)  // dataOffset starts at 160 (position 5)

        let memoryPointerAfterIds := copyArrayToMemory(add(memoryPointer, 0xa4), idOffset)
        let memoryPointerAfterAmounts := copyArrayToMemory(memoryPointerAfterIds, amountOffset)
        let endMemoryPointer := copyDataToMemory(memoryPointerAfterAmounts, dataOffset)

        // call(g, a, v, in, insize, out, outsize)
        // store result of call into location 0 in memory
        let success := call(gas(), to, 0, 0x80, sub(endMemoryPointer, 0x80), 0x00, 0x20)
        logNumber(0, success)
        let returnData := mload(0)

        // revert if the call does not return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
        if iszero(eq(returnData, onERC1155BatchSelector)) {
          revert(0,0)
        }
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