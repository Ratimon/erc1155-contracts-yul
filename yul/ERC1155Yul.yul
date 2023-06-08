/**
 * @title ERC1155 Purely in Yul.
 * @notice The implementation of the ERC1155 entirely in Yul.
 * @notice EIP => https://eips.ethereum.org/EIPS/eip-1155
 *   https://smitrajput.notion.site/smitrajput/The-Dark-Arts-of-Yul-Explained-e0b2c178bc52437da1d101f4f96abbe4
 *   https://hackmd.io/@gn56kcRBQc6mOi7LCgbv1g/rJez8O8st
 */

 object "ERC1155Yul" {   
    /**
     * @notice Constructor
     */
    code {
        // Basic constructor
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }

    object "runtime" {
    /**
     * @notice Deployed contracts runtime code
     */
        code {

            // mapping(uint256 => mapping(address => uint256)) private _balances;
            // _balances[tokenID][userAddress][amount]

            // Declaration         - mapping(T1 => T2) v
            // Value               - v[key]
            // Location in storage - keccak256(key + v’s slot)

            function balances() -> slot { slot:= 0x00 }

            // mapping(address => mapping(address => bool)) private _operatorApprovals;
            // _operatorApprovals[account][operator]

            function operatorApprovals() -> slot { slot:= 0x01 }

            function uriLength() -> slot { slot := 0x02 }

            // [0x00 - 0x20) => Scratch Space
            // [0x20 - 0x40) => Scratch Space
            // [0x40 - 0x60) => Free memory pointer
            // [0x60 - ....) => Free memory

            setFreeMemoryPointer(0x80)

            // Dispatcher based on selector
            switch getSelector()

            // cast 4byte 0x731133e9
            // cast abi-encode "sumArray(uint256[])"  '[1,2,3]'
            // cast calldata "sumArray(uint256[])"  '[1,2,3]'

            // cast sig "mint(address,uint256,uint256)"
            case 0x156e29f6 {
                _mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
            }
            // cast sig "mint(address,uint256,uint256,bytes)"
            case 0x731133e9 {
                _mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
            }

            // cast sig "batchMint(address,uint256[],uint256[],bytes)"
            // cast calldata "batchMint(address,uint256[],uint256[],bytes)" 0xf8e81d47203a594245e36c48e151709f0c19fbe8 '[1,2,3]' '[11,21,31]' ""

            // calldata
            // function selector calling  eg. (`batchMint(address,uint256[],uint256[])`)
            // 0x0ca83480

            // param 1: `address to`
            // 000000000000000000000000f8e81d47203a594245e36c48e151709f0c19fbe8

            // param 2: offset of id array => 3* 32 = 96 bytes below (3 lines ) from start of 1st (address in this case) line
            // 0000000000000000000000000000000000000000000000000000000000000060

            // param 3: offset of amount array => 7* 32 = 224 bytes (7 lines ) below from start of  1st (address in this case) line
            // 00000000000000000000000000000000000000000000000000000000000000e0

            // length of id array
            // 0000000000000000000000000000000000000000000000000000000000000003

            // 0000000000000000000000000000000000000000000000000000000000000001
            // 0000000000000000000000000000000000000000000000000000000000000002
            // 0000000000000000000000000000000000000000000000000000000000000003

            // length of amount array
            // 0000000000000000000000000000000000000000000000000000000000000003

            // 000000000000000000000000000000000000000000000000000000000000000b
            // 0000000000000000000000000000000000000000000000000000000000000015
            // 000000000000000000000000000000000000000000000000000000000000001f

            case 0xb48ab8b6 {
                _batchMint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
            }
            // cast sig "safeTransferFrom(address,address,uint256,uint256)"
            case 0x0febdd49 {
                _safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3))
            }
            // cast sig "safeTransferFrom(address,address,uint256,uint256,bytes)"
            case 0xf242432a {
                _safeTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3))
            }
            // cast sig "safeBatchTransferFrom(address,address,uint256[],uint256[])"
            case 0xfba0ee64 {
                _safeBatchTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3))
            }
            // cast sig "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)"
            case 0x2eb2c2d6 {
                _safeBatchTransferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2), decodeAsUint(3))
            }
            // cast sig "setApprovalForAll(address,bool)"
            // setApprovalForAll(address,bool)
            case 0xa22cb465 {
                _setApprovalForAll(decodeAsAddress(0), decodeAsUint(1))
            }
            // cast sig "balanceOf(address,uint256)"
            // balanceOf(address,uint256)
            case 0x00fdd58e {
                returnUint(_balanceOf(decodeAsAddress(0), decodeAsUint(1)))
            }
            // cast sig "balanceOfBatch(address[],uint256[])"
            // balanceOfBatch(address[],uint256[])
            case 0x4e1273f4 {
                returnUint(_balanceOfBatch(decodeAsUint(0), decodeAsUint(1)))
            }
            // cast sig "isApprovedForAll(address,address)"
            // isApprovedForAll(address,address)
            case 0xe985e9c5 {
                returnUint(_isApprovedForAll(decodeAsAddress(0), decodeAsAddress(1)))
            }
            // No fallback functions
            default {
                revert(0, 0)
            }

            /* ---------- internal functions ---------- */
            function _mint(to, id, amount) {
                _doZeroAddressCheck(to)
                let location := getNestedMappingLocation(balances(), id, to)
                // store the increased token amount at the location of balance
                sstore(location, safeAdd(sload(location), amount))
                _emitTransferSingle(caller(), 0x00, to, id, amount)
            }

            function _batchMint(to, idsSizeOffset, amountsSizeOffset) {
                _doZeroAddressCheck(to)
                let idsSize, idsIndex := decodeAsArray(idsSizeOffset)
                let amountsSize, amountsIndex := decodeAsArray(amountsSizeOffset)
                _doLengthMismatchCheck(idsSize,amountsSize)
                for { let i:= 0 } lt(i, idsSize) { i:= add(i, 1)}
                {
                    _mint(to, calldataload(idsIndex), calldataload(amountsIndex))
                    idsIndex := add(idsIndex, 0x20)
                    amountsIndex := add(amountsIndex, 0x20)
                }
            }

            function _setApprovalForAll(operator, approved) {
                if eq(operator, approved) {
                    // revert with: APPROVE_SELF
                    // cast --format-bytes32-string "APPROVE_SELFS"
                    mstore(0x00, 0x415050524f56455f53454c465300000000000000000000000000000000000000)
                    revert(0x00, 0x20)
                }
                let location := getNestedMappingLocation(operatorApprovals(), caller(), operator)
                sstore(location, approved)
            }

            function _safeTransferFrom(from, to, id, amount) {

                _doZeroAddressCheck(to)
                _doApprovalCheck(from)

                let fromLocation := getNestedMappingLocation(balances(), id, from)
                let fromBalance := sload(fromLocation)
                _doSufficientBalanceCheck(fromBalance, amount)
                // store the updated token amount at the location of balance
                sstore(fromLocation, safeSub(fromBalance, amount))
                let toLocation := getNestedMappingLocation(balances(), id, to)
                sstore(toLocation, safeAdd(sload(toLocation), amount))

                _emitTransferSingle(caller(), from, to, id, amount)
            }

            function _safeBatchTransferFrom(from, to, idsSizeOffset, amountsSizeOffset) {

                _doZeroAddressCheck(to)
                _doApprovalCheck(from)

                let idsSize, idsIndex := decodeAsArray(idsSizeOffset)
                let amountsSize, amountsIndex := decodeAsArray(amountsSizeOffset)

                _doLengthMismatchCheck(idsSize, amountsSize)

                let finalMemorySize := mul(add(0x40, mul(idsSize, 0x20)),2)

                // memory

                // param 1: offset of the id array => 2 * 32 = 64 bytes (2 lines ) from start of 1st line (this line)
                // 0000000000000000000000000000000000000000000000000000000000000040

                // param 2: offset of the amount array => n * 2 + n * 32 = 64 + n* 32 bytes (2 + n lines ) below from start of 1st line (this line)
                // 00000000000000000000000000000000000000000000000000000000000000??

                // length of id array
                // 000000000000000000000000000000000000000000000000000000000000000n

                // element
                // 0000000000000000000000000000000000000000000000000000000000000001
                // 0000000000000000000000000000000000000000000000000000000000000002
                // 0000000000000000000000000000000000000000000000000000000000000003
                // 0000000000000000000000000000000000000000000000000000000000000004
                // 0000000000000000000000000000000000000000000000000000000000000005

                // length of amount array
                // 000000000000000000000000000000000000000000000000000000000000000n

                // store the id array pointer (0x40), starting at the free memory location (0x80)
                mstore(getFreeMemoryPointer(), 0x40)
                // store the idsSize
                mstore(add(0x40, getFreeMemoryPointer()), idsSize)

                // store the amount array pointer (0x40 + 1 length + the size of array ), at the increased location (0x80 + 0x20)
                let amountsArrayPointer := add(0x40, mul(add (1, idsSize), 0x20))
                // debugEmit(amountsArrayPointer) //8
                mstore(add(0x20, getFreeMemoryPointer()), amountsArrayPointer)
                // store the amountsSize
                mstore(add(amountsArrayPointer, getFreeMemoryPointer()), amountsSize)

                // 0x60 counts for 2 pointers and 1 length of 1st array
                let idsIndexPointer := add(getFreeMemoryPointer(), 0x60 )
                // debugEmit(idsIndexPointer)      //7
                // 0x40 + 2 length + the size of array
                let amountsIndexPointer := add(getFreeMemoryPointer(), add(amountsArrayPointer, 0x20))
                // debugEmit(amountsIndexPointer) //13

                for { let i:= 0 } lt(i, idsSize) { i:= add(i, 1)}
                {
                    let tokenId := calldataload(idsIndex)
                    let cachedAmount := calldataload(amountsIndex)

                    let fromLocation := getNestedMappingLocation(balances(), tokenId, from)
                    let fromBalance := sload(fromLocation)
                    _doSufficientBalanceCheck(fromBalance, cachedAmount)
                    // store the updated token amount at the location of balance
                    sstore(fromLocation, safeSub(fromBalance, cachedAmount))
                    let toLocation := getNestedMappingLocation(balances(), tokenId, to)
                    sstore(toLocation, safeAdd(sload(toLocation), cachedAmount))

                    idsIndex := add(idsIndex, 0x20)
                    amountsIndex := add(amountsIndex, 0x20)

                    mstore(idsIndexPointer, tokenId)
                    mstore(amountsIndexPointer, cachedAmount)

                    idsIndexPointer := add(idsIndexPointer, 0x20)
                    amountsIndexPointer := add(amountsIndexPointer, 0x20)

                }
                // getFreeMemoryPointer()
                _emitTransferBatch(caller(), from, to, 0x80, finalMemorySize)
            }
            
            function _balanceOf(account, id) -> amount {
                let location := getNestedMappingLocation(balances(), id, account)
                amount := sload(location)
            }

            function _isApprovedForAll(account, operator) -> approved {
                let location := getNestedMappingLocation(operatorApprovals(), account, operator)
                approved := sload(location)
            }

            function _balanceOfBatch(accountsSizeOffset, idsSizeOffset) -> amount {

                let accountsSize, accountsIndex := decodeAsArray(accountsSizeOffset)
                let idsSize, idsIndex := decodeAsArray(idsSizeOffset)

                _doLengthMismatchCheck(accountsSize, idsSize)

                let finalMemorySize := add(0x40, mul(idsSize, 0x20))

                // initialize the array for return, according to the standard
    
                // offset of amount array => 1* 32 = 32 bytes (1 line ) below from start of  1st (address in this case) line
                // 0000000000000000000000000000000000000000000000000000000000000020 - offset to the start of data (The ABI encoding)

                // length of array
                // 000000000000000000000000000000000000000000000000000000000000000? - length

                // element
                // 0000000000000000000000000000000000000000000000000000000000000001

                // store the amount array pointer (0x20), starting at the free memory location (0x80)
                mstore(getFreeMemoryPointer(), 0x20)
                increaseFreeMemoryPointer()

                // store the length of the amount array
                mstore(getFreeMemoryPointer(), accountsSize)
                increaseFreeMemoryPointer()

                // loop and get the balances from the given slots & ids and store them
                for { let i := 0 } lt(i, accountsSize) { i := add(i, 1) }
                {
                    let owner := calldataload(accountsIndex)
                    let tokenId := calldataload(idsIndex)
                    let cachedAmount := _balanceOf(owner, tokenId)

                    mstore(getFreeMemoryPointer(), cachedAmount)
                    increaseFreeMemoryPointer()

                    accountsIndex := add(accountsIndex, 0x20)
                    idsIndex := add(idsIndex, 0x20)
                }

                return(0x80, finalMemorySize)

            }

            // @dev gets the location where values are stored in a nested mapping
            function getNestedMappingLocation(mappingSlot, key1, key2 ) -> location {
                // v[id][account] => keccak256(id + v’s slot location)
                mstore(0x00, key1)                       // store storage slot of mapping
                mstore(0x20, mappingSlot)                // store 1st key

                let hash := keccak256(0, 0x40)
                // keccak256(id + v’s slot location) => keccak256(account +keccak256(id + v’s slot))

                mstore(0x00, key2)                       // store 2nd key
                mstore(0x20, hash)                       // store location

                location := keccak256(0x00, 0x40)             // get hash of those => location
            }

            /* -------------------------------------------------- */
            /* ---------- EVENTS EMITTING FUNCTIONS ------------- */
            /* -------------------------------------------------- */

            // event TransferSingle(
            //     address indexed operator,
            //     address indexed from,
            //     address indexed to,
            //     uint256 id,
            //     uint256 amount
            // );

            function _emitTransferSingle(operator, from, to, tokenId, amount) {
                // cast keccak "TransferSingle(address,address,address,uint256,uint256)"
                let hash := 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
                mstore(0, tokenId)
                mstore(0x20, amount)
                log4(0, 0x40, hash, operator, from, to)
            }

            // event TransferBatch(
            //     address indexed operator,
            //     address indexed from,
            //     address indexed to,
            //     uint256[] ids,
            //     uint256[] amounts
            // );

            function _emitTransferBatch(operator, from, to, memoryIndex, memorySize) {
                // cast keccak "TransferBatch(address,address,address,uint256[],uint256[])"
                let hash := 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb
                log4(memoryIndex, memorySize, hash, operator, from, to)
            }

            /* ---------------------------------------------------------- */
            /* ---------------- ERROR HELPER FUNCTIONS ----------------- */
            /* ---------------------------------------------------------- */

            function _doZeroAddressCheck(account) {
                if eq(account, 0x00) {
                    // revert with: ZERO_ADDRESS
                    // cast --format-bytes32-string "ZERO_ADDRESS"
                    mstore(0x00, 0x5a45524f5f414444524553530000000000000000000000000000000000000000)
                    revert(0x00, 0x20)
                }
            }

            function _doLengthMismatchCheck(firstLength, secondLength) {
                if iszero(eq(firstLength, secondLength)) {
                    // revert with: LENGTH_MISMATCH
                    // cast --format-bytes32-string "LENGTH_MISMATCH"
                    mstore(0x00, 0x4c454e4754485f4d49534d415443480000000000000000000000000000000000)
                    revert(0x00, 0x20)
                }
            }

            function _doApprovalCheck(from) {
                // require(
                //     from == _msgSender() || isApprovedForAll(from, _msgSender()),
                //     "ERC1155: caller is not token owner or approved"
                // );
                if iszero(eq(from, caller())) {
                    if iszero(_isApprovedForAll(from, caller())) {
                        // cast --format-bytes32-string "NOT_TOKEN_OWNER_OR_APPROVED"
                        mstore(0x00, 0x4e4f545f544f4b454e5f4f574e45525f4f525f415050524f5645440000000000)
                        revert(0x00, 0x20)
                    }
                }
            }

            function _doSufficientBalanceCheck(fromBalance, amount) {
                if lt(fromBalance, amount) {
                    // cast --format-bytes32-string NOT_ENOUGH_BALANCE
                    mstore(0x00, 0x4e4f545f454e4f5547485f42414c414e43450000000000000000000000000000)
                    revert(0x00, 0x20)
                }
            }

            /* ---------------------------------------------------------- */
            /* ---------------- MEMORY HELPER FUNCTIONS ----------------- */
            /* ---------------------------------------------------------- */

            // @dev By default, 0x40 stores the next free memory location
            // @return the free memory pointer position which is 0x40
            function getFreeMemoryPointerPosition() -> pos {
                pos := 0x40
            }

            // @dev the first memory slot for dynamic memory
            // @return the value  stored in the memory pointer position (initialized as 0x80)
            function getFreeMemoryPointer() -> value {
                value := mload(getFreeMemoryPointerPosition())
            }

            // @dev increase the memory pointer value by 32 bytes (initialy 0x80 + 0x20 => 0xa0)
            function increaseFreeMemoryPointer() {
                mstore(getFreeMemoryPointerPosition(), add(getFreeMemoryPointer(), 0x20))
            }

            // @dev sets new memory pointer to a given memory slot (default value is 0x80)
            function setFreeMemoryPointer(slot) {
                mstore(getFreeMemoryPointerPosition(), slot)
            }


            /* -------------------------------------------------- */
            /* ---------- CALLDATA DECODING FUNCTIONS ----------- */
            /* -------------------------------------------------- */
            // @dev decodes the function selector from the calldata
            function getSelector() -> selector {
                selector := shr(0xe0, calldataload(0))
            }

            // @dev decodes the calldata then masks 12 bytes to grab an address( 20bytes)
            // @param The offset of the uint to read in calldata
            // @return The decoded value as a address
            function decodeAsAddress(offset) -> value {
                value := decodeAsUint(offset)
                if iszero(iszero(and(value, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
            }

            // @dev decodes the calldata, starting from the 4th offset to skip selector
            // @param The offset of the uint to read in calldata
            // @return The decoded value as a uint
            function decodeAsUint(offset) -> value {
                let pos := add(4, mul(offset, 0x20))
                if lt(calldatasize(), add(pos, 0x20)) {
                    revert(0, 0)
                }
                value := calldataload(pos)
            }

            /// @notice A function to decode a calldata dynamic array
            /// @param The pointer at which the array is stored in calldata (must point to the size argument)
            /// @return The size of the array
            /// @return The offset at which first argument is stored
            function decodeAsArray(pointer) -> size, firstElementIndex {
                size := calldataload(add(4, pointer))

                if lt(calldatasize(), add(pointer, mul(size, 0x20))) {
                    revert(0, 0)
                }

                // firstElementIndex := add(0x24, pointer)
                // 32byte + 4 byte
                firstElementIndex := add(36, pointer)

            }

            // @dev returns memory data (from offset, size of return value)
            // @param from (starting address in memory) to return, e.g. 0x00
            // @param to (size of the return value), e.g. 0x20 for 32 bytes 0x40 for 64 bytes
            function returnMemory(offset, size) {
                return(offset, size)
            }

            // @dev stores the value in memory 0x00 and returns that part of memory
            function returnUint(v) {
                mstore(0x00, v)
                return(0x00, 0x20)
            }

            // @dev helper function that returns true (uint of 1 === true)
            function returnTrue() {
                returnUint(1)
            }

            /* ------------------------------------------------------- */
            /* -------------- UTILITY HELPER FUNCTIONS --------------- */
            /* ------------------------------------------------------- */

            // @dev Add function with overflow and underflow protections
            function safeAdd(a, b) -> result {
                result := add(a, b)
                if or(lt(result, a), lt(result, b)) { revert(0, 0) }
            }

            function safeSub(a, b) -> result {
                result := sub(a, b)
                if gt(result, a) { revert(0, 0) }
            }

            // function debugEmit(value) {
            //     log1(0, 0x00, value)
            // }

        }
    }

}