// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;/**
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint16`
 * (`Uint16Set`) are supported.
 */
library EnumerableSetUint16 {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes2 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes2.

    struct Set {
        // Storage of set values
        bytes2[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes2 => uint16) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes2 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = uint16(set._values.length);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes2 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint16 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint16 toDeleteIndex = valueIndex - 1;
            uint16 lastIndex = uint16(set._values.length) - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes2 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes2 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint16) {
        return uint16(set._values.length);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint16 index) private view returns (bytes2) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }



    // Uint16Set

    struct Uint16Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Uint16Set storage set, uint16 value) internal returns (bool) {
        return _add(set._inner, bytes2(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Uint16Set storage set, uint16 value) internal returns (bool) {
        return _remove(set._inner, bytes2(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Uint16Set storage set, uint16 value) internal view returns (bool) {
        return _contains(set._inner, bytes2(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Uint16Set storage set) internal view returns (uint16) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Uint16Set storage set, uint16 index) internal view returns (uint16) {
        return uint16(_at(set._inner, index));
    }


}