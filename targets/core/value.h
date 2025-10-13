#pragma once

#include "begin_header.h"
begin_header
// ============================================================================

/**
	Opaque type for internal value data.

 	Every struct that should act as a value type must have a pointer to
 	this type as its first field. Normally you do not use this type directly;
	use the `ValueStruct` macro instead.

	@code
	struct String {
		ValueStruct
		// String-specific fields follow
	}
	@endcode
*/
struct Value;
#define ValueStruct  struct Value * _valueStructPtr;


/**
	The hash value of a value to be returned by `HashFunc_Value`.

	@see HashFunc_Value
*/
typedef uint32_t Hash_Value;


/**
	How to perform a copy.
*/
defEnum( CopyStyle_Value, int ) {
	/**
		Copy the value itself but don't copy any value it references.
		Referenced values may just be shared with the copy.

		Never passed to immutable values, they require no copying.
	*/
	Shallow_CopyStyle_Value = 1,

	/**
		Copy the value along with all values it references.

		Never passed to immutable values, they require no copying and values
		they reference should neither (if state relevant, those should be
		immutable or frozen).
	*/
	Deep_CopyStyle_Value,

	/**
		Copy the value along with all values it references. The returned copy
		must be thread-safe.

		This style is also passed to immutable values, since all referenced
		values must be made thread-safe and therefore copy must be invoked on
		them. Immutable values themselves do not produce a copy of themselves;
		they just return a reference to themselves without even retaining it
		(`copy_Value()` will already retain them internally prior to return).
	*/
	ThreadSafe_CopyStyle_Value
};


/**
	Returns a hash value that represents the value's current state.
	If `hashIsDeep` is `true`, two objects that are equal according to
	`EqualFunc_Value` must produce the same hash value. Different objects
	may still collide.

	If `hashIsDeep` is `false`, only include the state local to the object
	itself. Do not incorporate state of referenced objects, so changes in a
	referenced object do not change this hash value.
*/
typedef Hash_Value (HashFunc_Value)(
	const void * anyValue, bool hashIsDeep
);


/**
	Compare two values and return true only if they are fully functionally
	equivalent. All observable behavior and referenced state must match
	exactly. Values are never `nil` and `anyOtherValue` is guaranteed to be
	of the same type as `anyValue`.
*/
typedef bool (EqualFunc_Value)(
	const void * anyValue, const void * anyOtherValue
);


/**
	Create a copy of the value.
	Style defines how the copy is performed and what result is returned.
	@see CopyStyle_Value
 */
typedef void * (CopyFunc_Value)(
	const void * anyValue, enum CopyStyle_Value style
);

/**
	Freeze all referenced values (deep).
	Do not freeze the value itself. Use this to ensure referenced objects
	are safe for sharing or copy-on-write.
*/
typedef void (FreezeFunc_Value)( const void * anyValue );

/**
	Perform additional clean-up when an object is about to be destroyed,
	e.g. discard objects it references. Memory for the object itself is
	freed by the runtime after this hook returns.
*/
typedef void (DestroyFunc_Value)( const void * anyValue );


/**
	Create a human-readable description string of the value.
	The caller must free the returned string.
*/
typedef char * (CreateDescFunc_Value)( const void * anyValue );


/**
	@param name Name of the value type as a printable string. For a given
		type, the pointer identity must be the same across instances
		(`==` must hold), not just the string contents.
	@param hashFunc Function to compute a value's hash. See `HashFunc_Value`.
	@param copyFunc Function to copy the value. See `CopyFunc_Value`.
	@param equalFunc Function to compare objects. See `EqualFunc_Value`.
	@param freezeFunc Function to freeze all values this value references. Set
		to `nil` if the value does not reference any other other values or is
		immutable and can only reference frozen values. See `FreezeFunc_Value`.
	@param destroyFunc Function for extra clean-up before destruction. Set to
		`nil` if no clean-up is needed beyond freeing memory. See
		`DestroyFunc_Value`.
	@param createDescFunc Function that creates a human-readable description
		of the object. Useful for logging and debugging. Caller frees the
		returned string. See `CreateDescFunc_Value`.

	@note
	Two values are only considered to be of exactly the same type, if they
	both point to the same type descriptor (== must be true) and if they both
	have the same `name` (again, == must be true)!
*/
struct ValueTypeDescriptor {
	const char * name;
	HashFunc_Value * hashFunc;
	CopyFunc_Value * copyFunc;
	EqualFunc_Value * equalFunc;
	Opt(FreezeFunc_Value *) freezeFunc;
	Opt(DestroyFunc_Value *) destroyFunc;
	CreateDescFunc_Value * createDescFunc;
};

// ----------------------------------------------------------------------------

/**
	Increment the object's reference count and return the same pointer.
*/
public
Opt(void *) retain_Value( Opt(void *) value );


/**
	Balance a previous creation or retain. Destroys the value when the
	reference count reaches zero.
*/
public
void discard_Value( Opt(void *) value );


/**
	Get name of the value type as a printable string.
*/
public
const char * getName_Value( Opt(void *) value );


/**
	Returns a hash value that represents the value's current state.
	If `hashIsDeep` is `true`, two objects that are equal according to
	`EqualFunc_Value` must produce the same hash value. Different objects
	may still collide.

	If `hashIsDeep` is `false`, only include the state local to the object
	itself. Do not incorporate state of referenced objects, so changes in a
	referenced object do not change this hash value.
*/
public
Hash_Value hash_Value( void * value, bool hashIsDeep );


/**
	Either returns the same value with an increased retain count (if
	immutable), or returns a new copy (deep or shallow depending on the style).

	If the style requests a thread-safe copy, the result must be safe to use
	across threads. For mutable values this usually requires a deep copy,
	unless the value uses a thread-safe copy-on-write mechanism. For immutable
	values this function ensures the object itself becomes thread-safe.

	The `copyFunc` in `ValueTypeDescriptor` is always called for mutable
	values, so it can safely call this function on all referenced values.
	For immutable values `copyFunc` is only called when a thread-safe copy is
	requested, because only then must it also call this function on all
	referenced values to make them thread-safe as well.
 */
public
Opt(void *) copy_Value( Opt(void *) value, enum CopyStyle_Value style );


/**
	Test two values for equality.

	@return `true` only if they are fully functionally equivalent. All
	observable behavior and referenced state must match exactly. Always
	`false` if either value is `nil`!
*/
public
bool isEqual_Value( Opt(void *) value, Opt(void *) otherValue );


/**
	Mark the value for copy-on-write on the next modification because an
	immutable reference to that value is required. Does nothing if the value
	is immutable, as immutable values are always frozen.
*/
public
Opt(const void *) freeze_Value( Opt(void *) value );


/**
	Create a human readable description of the value.
	Caller must free description using `free()`.
*/
public
const char * createDescription_Value( Opt(void *) value );


/**
	If the value is not frozen, just retains the value and returns it.
	If the value is frozen, creates a deep copy and returns it.
*/
public
Opt(void *) unfreeze_Value( Opt(void *) value );


/**
	Discards the current value `valuePtr` points to, retains `newValue` and
	assigns it to `valuePtr`. It does in a safe manner, so nothing goes wrong,
	even if `valuePtr` already points to `newValue`.

	@code
	// Equivalent code but set_Value() is more efficient
	if (*valuePtr == newValue) return false;
	def oldValue = *valuePtr;
	*valuePtr = retain_Value(newValue);
	discard_Value(oldValue);
	return true;
	@endcode

	@returns Whether `valuePtr` was actually mutated or not.
*/
public
void set_Value( Opt(void *) * valuePtr,  Opt(void *) newValue );




// ----------------------------------------------------------------------------

/**
	@param size Total size of the value in bytes, including the leading
		`ValueHeader`.
	@param typeDesc Pointer to the value's type descriptor.

	@return Pointer to a newly allocated object block. You may cast the
		result to any structure of the requested size, provided the
		structure begins with a field of type `struct Object * <any_name>;`.

	@code
	struct String {
		ValueHeader
		// String-specific fields follow
	};

	String *str = create_Value(false, sizeof(String), &StringType);
	@endcode

	@note
	All fields are zero-initialized (0, false, nil, etc.).

	@warning
	If the structure ends with a flexible array member
	(e.g. `uint8_t data[];` or `uint8_t data[0];`), include the
	runtime size of that array in `size`.
*/
public
void * create_Value(
	bool mutable,
	uint16_t size,
	const struct ValueTypeDescriptor * const typeDesc
);

// ============================================================================
end_header
#include "end_header.h"