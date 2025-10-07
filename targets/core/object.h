#pragma once

#include "begin_header.h"
begin_header
// ============================================================================

typedef uint32_t HashValue_Object;


/**
	Returns a hashed value representing the objects current internal state.
	If `hashIsDeep` is `true`, the returned value must be the same for two
	objects that compare equal using their `CompareFunc_Object` function.
	Yet two non-equal objects may still return the same hash value.
	If `hashIsDeep` is false, the hash must not include state of any
	referenced objects but only of the object itself, thus when a referenced
	object changes in state, the this hash value would not.
*/
typedef HashValue_Object (HashFunc_Object)(
	const void * anyObject, bool hashIsDeep
);

/**
	Either create a copy of the object itself (`copyIsDeep` is `false`)
	or a deep copy of the object and all objects it references
	(`copyIsDeep` is `true`).
 */
typedef void * (CopyFunc_Object)( const void * anyObject, bool copyIsDeep );

/**
	Freeze all referenced objects (always deep).
	The object must not freeze itself!
*/
typedef void * (FreezeFunc_Object)( const void * anyObject );

/**
	Performs additional clean-up when an object is about to be destroyed,
	e.g. discarding objects it refers to.
*/
typedef void (DestroyFunc_Object)( const void * anyObject );

/**
	Compares the object to another one, returns `true` only if both objects are
	functional equivalent in **EVERY** aspect. This may require also comparing
	referenced objects in case those do change functionality.
*/
typedef bool (CompareFunc_Object)( const void *_nil anyObject );

/**
	Creates a human readable description string of the object.
	Caller must free returned string.
*/
typedef char * (CreateDescFunc_Object)( const void * anyObject );


/**
	@param name Name of the object as printable string. For the same object
		type, it's not sufficient that this string has the same "value", it
		actually must be the same string (== comparison must be true!).
	@param hashFunc Function to calculate the hash of an object.
		See `HashFunc_Object` for details.
	@param copyFunc Function to copy the object. If the object is immutable,
		just set to `nil` and the object is never copied but just retained.
		If the object can be copied by just cloning it byte for byte, set it
		to `CloneCopyFunc_Object`. See `CopyFunc_Object` for details.
	@param freezeFunc Function to freeze all objects this object refers to.
		If the object does not refer to any other objects, just set to `nil`.
		See `FreezeFunc_Object` for details.
	@param destroyFunc Function to perform additional clean-up when the object
		is about to be destroyed. Set it to `nil` if no clean up is required
		other than freeing the object's memory. See `DestroyFunc_Object` for
		details.
	@param compareFunc Function to compare the object. If the object can be
		compared by just using `memcmp()`, set it to `nil`. See
		`CompareFunc_Object` for details.
	@param createDescFunc Function creates a human readable description of
		the object. Useful for logging and debugging. Caller must free returned
		string. See `CreateDescFunc_Object` for details.
*/
struct ObjectType {
	const char * name;
	HashFunc_Object * hashFunc;
	CopyFunc_Object *_nil copyFunc;
	FreezeFunc_Object *_nil freezeFunc;
	DestroyFunc_Object *_nil destroyFunc;
	CompareFunc_Object *_nil compareFunc;
	CreateDescFunc_Object * createDescFunc;
};

// ----------------------------------------------------------------------------

/**
	Retains an object and returns the retained object.
*/
public
void *_nil retain_Object( void *_nil object );


/**
	Ensure that next time the object is modified,
	a copy is made and returned because someone requires an immutable
	reference to it. Does nothing if the object is immutable.

	@see ObjectType->copyFunc
*/
public
void *_nil freeze_Object( void *_nil object );


/**
	Balance creation or retain.
	Destroys object when reference counter becomes zero.
*/
public
void discard_Object( void *_nil object );

/**
	@param size Total size of the object in bytes, including the leading
		Object pointer field.
	@param type Pointer to the object's type descriptor.

	@return A pointer to a newly allocated object block. The result can be
		cast to any structure of the specified size, provided that the
		structure begins with a field of type `struct Object * <any_name>;`.

	@code
	typedef struct {
		struct Object * objHeader; // Name doesn't matter!
		// String-specific fields follow
	} String;

	String *str = create_Object(sizeof(String), &StringType);
	@endcode

	@note
	All object fields are initialized with zero (0, false, nil, etc.).

	@warning
	If the structure ends with a flexible array member
	(e.g. `uint8_t data[];` or `uint8_t data[0];`), include the
	additional runtime size of that array in `size`!
*/
public
void * create_Object(
	uint16_t size,
	const struct ObjectType * const type
);


// ============================================================================
end_header
#include "end_header.h"