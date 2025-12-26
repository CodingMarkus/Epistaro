#pragma once

#include "hasher.h"

#include "base/begin_header.h"
begin_header
// ============================================================================

/**
	Provide a list of all referenced values.

	@param referencedValues `nil` terminated list of values referenced.

	@see IterateRefsFunc_Value
*/
typedef void IterateRefsCallback_Value(
	Opt(void *) referencedValues[_opt]
);


/**
	Provide access to all values a value references.

	Sample usage:

	```
	struct SomeValue {
		ValueStruct

		Value1 * v1;
		Value2 * v2;
		Value3 * v3;
	}

	void iterate(
		const void * anyObject,
		IterateRefsCallback_Value callback )
	{
		def val = (struct SomeValue *)anyValue;
		callback((void * []){ &val->v1, &val->v2, &val->v3, nil });
	}

	```
*/
typedef void (IterateRefsFunc_Value)(
	const void * anyObject,
	IterateRefsCallback_Value callback
);


/**
	Compute a hash that reflects the value's state.

	The hash must change when any state that affects `EqualFunc_Value` changes.
	Equal values must yield identical hashes. Collisions remain possible.
*/
typedef void (HashFunc_Value)( const void * anyValue, Hasher hasher );


/**
	Compare two values and return `true` only if they are fully functionally
	equivalent. All observable behavior and referenced state must match
	exactly. Both values are never `nil` and `anyOtherValue` is guaranteed to
	be of the same type as `anyValue`.
*/
typedef bool (EqualFunc_Value)(
	const void * anyValue, const void * anyOtherValue
);


/**
	Create a copy of the value.

	If `copyIsDeep` is `true`, nested or referenced data will also be
	recursively copied, producing a fully independent clone; otherwise only
	a shallow copy is made.
 */
typedef void * (CopyFunc_Value)(
	const void * anyValue, bool copyIsDeep
);


/**
	Perform optional additional clean-up when an object is about to be
	destroyed, e.g. releasing resources that are not value references.
*/
typedef void (DestroyFunc_Value)( const void * anyValue );


/**
	Create a human-readable description string of the value.
	The caller must free the returned string.
*/
typedef char * (CreateDescFunc_Value)( const void * anyValue );


// /**
// 	@param name Name of the value type as a printable string. For a given
// 		type, the pointer identity must be the same across instances
// 		(`==` must hold), not just the string contents.
// 	@param hashFunc Function to compute a value's hash. See `HashFunc_Value`.
// 	@param copyFunc Function to copy the value. See `CopyFunc_Value`.
// 	@param equalFunc Function to compare objects. See `EqualFunc_Value`.
// 	@param freezeFunc Function to freeze all values this value references. Set
// 		to `nil` if the value does not reference any other other values or is
// 		immutable and can only reference frozen values. See `FreezeFunc_Value`.
// 	@param destroyFunc Function for extra clean-up before destruction. Set to
// 		`nil` if no clean-up is needed beyond freeing memory. See
// 		`DestroyFunc_Value`.
// 	@param createDescFunc Function that creates a human-readable description
// 		of the object. Useful for logging and debugging. Caller frees the
// 		returned string. See `CreateDescFunc_Value`.

// 	@note
// 	Two values are only considered to be of exactly the same type, if they
// 	both point to the same type descriptor (== must be true) and if they both
// 	have the same `name` (again, == must be true)!
// */
struct ValueTypeDescriptor {
	const char * name;
	HashFunc_Value * hashFunc;
	CopyFunc_Value * copyFunc;
	EqualFunc_Value * equalFunc;
	Opt(DestroyFunc_Value *) destroyFunc;
	CreateDescFunc_Value * createDescFunc;
};

// // ----------------------------------------------------------------------------

/**
	Increment the object's reference count and return the same pointer.
*/
Opt(void *) retain_Value( Opt(void *) value );


/**
	Balance a previous creation or retain. Destroys the value when the
	reference count reaches zero.
*/
void discard_Value( Opt(void *) value );


/**
	Get name of the value type as a printable string.
*/
Opt(const char *) getName_Value( Opt(void *) value );


// /**
// 	Returns a hash value that represents the value's current state.
// 	If `hashIsDeep` is `true`, two objects that are equal according to
// 	`EqualFunc_Value` must produce the same hash value. Different objects
// 	may still collide.

// 	If `hashIsDeep` is `false`, only include the state local to the object
// 	itself. Do not incorporate state of referenced objects, so changes in a
// 	referenced object do not change this hash value.
// */
// public
// Hash_Value hash_Value( void * value, bool hashIsDeep );


// /**
// 	Either returns the same value with an increased retain count (if
// 	immutable), or returns a new copy (deep or shallow depending on the style).

// 	If the style requests a thread-safe copy, the result must be safe to use
// 	across threads. For mutable values this usually requires a deep copy,
// 	unless the value uses a thread-safe copy-on-write mechanism. For immutable
// 	values this function ensures the object itself becomes thread-safe.

// 	The `copyFunc` in `ValueTypeDescriptor` is always called for mutable
// 	values, so it can safely call this function on all referenced values.
// 	For immutable values `copyFunc` is only called when a thread-safe copy is
// 	requested, because only then must it also call this function on all
// 	referenced values to make them thread-safe as well.
//  */
// public
// Opt(void *) copy_Value( Opt(void *) value, enum CopyStyle_Value style );


/**
	Test two values for equality.

	@return `true` only if they are fully functionally equivalent. All
	observable behavior and referenced state must match exactly. Always
	`false` if either value is `nil`!
*/
bool isEqual_Value( Opt(const void *) value, Opt(const void *) otherValue );


// /**
// 	Mark the value for copy-on-write on the next modification because an
// 	immutable reference to that value is required. Does nothing if the value
// 	is immutable, as immutable values are always frozen.
// */
// public
// Opt(const void *) freeze_Value( Opt(void *) value );


// /**
// 	Create a human readable description of the value.
// 	Caller must free description using `free()`.
// */
// public
// const char * createDescription_Value( Opt(void *) value );


// /**
// 	If the value is not frozen, just retains the value and returns it.
// 	If the value is frozen, creates a deep copy and returns it.
// */
// public
// Opt(void *) unfreeze_Value( Opt(void *) value );


// /**
// 	Discards the current value `valuePtr` points to, retains `newValue` and
// 	assigns it to `valuePtr`. It does in a safe manner, so nothing goes wrong,
// 	even if `valuePtr` already points to `newValue`.

// 	@code
// 	// Equivalent code but set_Value() is more efficient
// 	if (*valuePtr == newValue) return false;
// 	def oldValue = *valuePtr;
// 	*valuePtr = retain_Value(newValue);
// 	discard_Value(oldValue);
// 	return true;
// 	@endcode

// 	@returns Whether `valuePtr` was actually mutated or not.
// */
// public
// void set_Value( Opt(void *) * valuePtr,  Opt(void *) newValue );




// ----------------------------------------------------------------------------

/**
	@param size Total size of the encapsulated struct in bytes, including
		any struct padding.
	@param typeDesc Pointer to the value's type descriptor.

	@return Pointer to the newly allocated value.

	```
	typedef NativeValue StringStorage;

	struct StringStorage {
		// StringStorage-specific fields
	};

	StringStorage * str = create_NativeValue(
		false, sizeof(struct StringStorage), &StringStorageType
	);
	```

	@note
	All fields are zero-initialized (0, false, nil, etc.).

	@warning
	If the structure ends with a flexible array member
	(e.g. `int8e data[];` or `int8e data[0];`), include the
	runtime size of that array in `size`.
*/
void * create_Value(
	bool mutable,
	uint16_t size,
	const struct ValueTypeDescriptor * const typeDesc
);

// ============================================================================
end_header
#include "base/end_header.h"