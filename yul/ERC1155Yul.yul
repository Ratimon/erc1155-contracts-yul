/**
 * @title ERC1155 Purely in Yul.
 * @notice The implementation of the ERC1155 entirely in Yul.
 * @notice EIP => https://eips.ethereum.org/EIPS/eip-1155
 *   https://smitrajput.notion.site/smitrajput/The-Dark-Arts-of-Yul-Explained-e0b2c178bc52437da1d101f4f96abbe4
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

            // mstore(0x80, calldataload(0))
            // return(0x80, calldatasize())
            /////

            // _balances[tokenID][userAddress][amount]
            // mapping(uint256 => mapping(address => uint256)) private _balances;

            // Declaration         - mapping(T1 => T2) v
            // Value               - v[key]
            // Location in storage - keccak256(key + v’s slot)

            function balances() -> slot { slot:= 0x00 }
            // mapping(address => mapping(address => bool)) private _operatorApprovals;
            function operatorApprovals() -> slot { slot:= 0x01 }

            function uriLength() -> slot { slot := 0x02 }

            // 0x00 - 0x20 => Scratch Space
            // 0x20 - 0x40 => Scratch Space
            // 0x40 - 0x60 => Free memory pointer
            // 0x60 - .... => Free memory

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

            // fn selector we're calling (`batchMint(address,uint256[],uint256[])`)
            // 0x0ca83480

            // `address to` param
            // 000000000000000000000000f8e81d47203a594245e36c48e151709f0c19fbe8

            // offset of id array => 3* 32 = 96 bytes below from start of 1st (address in this case) line
            // 0000000000000000000000000000000000000000000000000000000000000060

            // offset of amount array => 7* 32 = 224 bytes below from start of  1st (address in this case) line
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

            // cast sig "balanceOf(address,uint256)"
            // balanceOf(address,uint256)
            case 0x00fdd58e {
                returnUint(_balanceOf(decodeAsAddress(0), decodeAsUint(1)))
            }

            // cast sig "balanceOfBatch(address[],uint256[])"
            // balanceOfBatch(address[],uint256[])
            case 0x4e1273f4 {
                returnUint(_balanceOfBatch(decodeAsAddress(0), decodeAsUint(1)))
            }
            
            // No fallback functions
            default {
                revert(0, 0)
            }

            /* ---------- internal functions ---------- */
            function _mint(to, tokenId, amount) {
                
                if eq(to, 0x00) {
                    // revert with: ZERO_ADDRESS
                    // cast --format-bytes32-string "ZERO_ADDRESS"
                    mstore(0x00, 0x5a45524f5f414444524553530000000000000000000000000000000000000000)
                    revert(0x00, 0x20)
                }

                let location := getNestedMappingLocation(balances(), tokenId, to)
                // store the increased token amount at the location of balance
                sstore(location, safeAdd(sload(location), amount))
            }

            function _batchMint(to, idsSizeOffset, amountsSizeOffset) {

                if eq(to, 0x00) {
                    // revert with: ZERO_ADDRESS
                    // cast --format-bytes32-string "ZERO_ADDRESS"
                    mstore(0x00, 0x5a45524f5f414444524553530000000000000000000000000000000000000000)
                    revert(0x00, 0x20)
                }

                let idsSize, idsIndex := decodeAsArray(idsSizeOffset)
                let amountsSize, amountsIndex := decodeAsArray(amountsSizeOffset)

                if iszero(eq(idsSize, amountsSize)) {
                    // revert with: LENGTH_MISMATCH
                    // cast --format-bytes32-string "LENGTH_MISMATCH"
                    mstore(0x0, 0x4c454e4754485f4d49534d415443480000000000000000000000000000000000)
                    revert(0x0, 0x20)
                }

                for { let i:= 0 } lt(i, idsSize) { i:= add(i, 1)}
                {
                    _mint(to, calldataload(idsIndex), calldataload(amountsIndex))
                    idsIndex := add(idsIndex, 0x20)
                    amountsIndex := add(amountsIndex, 0x20)
                }

            }

            function _balanceOf(account, tokenId) -> amount {
                let location := getNestedMappingLocation(balances(), tokenId, account)
                amount := sload(location)
            }

            function _balanceOfBatch(accountsSizeOffset, idsSizeOffset) -> amount {

                let accountsSize, accountsIndex := decodeAsArray(accountsSizeOffset)
                let idsSize, idsIndex := decodeAsArray(idsSizeOffset)

                if iszero(eq(accountsSize, idsSize)) {
                    // revert with: LENGTH_MISMATCH
                    // cast --format-bytes32-string "LENGTH_MISMATCH"
                    mstore(0x0, 0x4c454e4754485f4d49534d415443480000000000000000000000000000000000)
                    revert(0x0, 0x20)
                }


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

            /* -------------------------------------------------- */
            /* ---------- CALLDATA ENCODING FUNCTIONS ----------- */
            /* -------------------------------------------------- */

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
        }
    }

}