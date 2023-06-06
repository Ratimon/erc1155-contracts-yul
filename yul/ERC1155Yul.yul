/**
 * @title ERC1155 Purely in Yul.
 * @notice The implementation of the ERC1155 entirely in Yul.
 * @notice EIP => https://eips.ethereum.org/EIPS/eip-1155
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
            // cast sig "mint(address,uint256,uint256,bytes)"
            // cast abi-encode "sumArray(uint256[])"  '[1,2,3]'
            // cast calldata "sumArray(uint256[])"  '[1,2,3]'

            // mint(address,uint256,uint256)
            case 0x156e29f6 {
                _mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
            }
            // mint(address,uint256,uint256,bytes)
            case 0x731133e9 {
                _mint(decodeAsAddress(0), decodeAsUint(1), decodeAsUint(2))
            }
            // balanceOf(address,uint256)
            case 0x00fdd58e {
                returnUint(_balanceOf(decodeAsAddress(0), decodeAsUint(1)))
            }
            
            // No fallback functions
            default {
                revert(0, 0)
            }

            /* ---------- internal functions ---------- */
            function _mint(to, tokenId, amount) {
                let location := getNestedMappingLocation(balances(), tokenId, to)
                // store the increased token amount at the location of balance
                sstore(location, safeAdd(sload(location), amount))
            }

            function _balanceOf(account, tokenId) -> amount {
                let location := getNestedMappingLocation(balances(), tokenId, account)
                amount := sload(location)
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
                mstore(0, v)
                return(0, 0x20)
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