#pragma once

#include "begin_header.h"
begin_header
// ============================================================================

typedef uint32_t HashValue_Object;


/**
	Returns a hash value that represents the object's current state.
	If `hashIsDeep` is `true`, two objects that are equal according to
	`CompareFunc_Object` must produce the same hash value. Different objects
	may still collide.
	If `hashIsDeep` is `false`, only include the state local to the object
	itself. Do not incorporate state of referenced objects, so changes in a
	referenced object do not change this hash value.
*/
typedef HashValue_Object (HashFunc_Object)(
	const void * anyObject, bool hashIsDeep
);

/**
	Create a copy of the object.
	If `copyIsDeep` is `false`, copy only the object itself.
	If `copyIsDeep` is `true`, also copy all referenced objects so the
	result is independent of the originals.
 */
typedef void * (CopyFunc_Object)( const void * anyObject, bool copyIsDeep );

/**
	Freeze all referenced objects (deep).
	Do not freeze the object itself. Use this to ensure referenced objects
	are safe for sharing or copy-on-write.
*/
typedef void * (FreezeFunc_Object)( const void * anyObject );

/**
	Perform additional clean-up when an object is about to be destroyed,
	e.g. discard objects it references. Memory for the object itself is
	freed by the runtime after this hook returns.
*/
typedef void (DestroyFunc_Object)( const void * anyObject );

/**
	Compare two objects and return `true` only if they are functionally
	equivalent in **EVERY** aspect. Include referenced objects when their
	state affects functionality.
*/
typedef bool (CompareFunc_Object)( const void *_nil anyObject );

/**
	Create a human-readable description string of the object.
	The caller must free the returned string.
*/
typedef char * (CreateDescFunc_Object)( const void * anyObject );


/**
	@param name Name of the object type as a printable string. For a given
		type, the pointer identity must be the same across instances
		(`==` must hold), not just the string contents.
	@param hashFunc Function to compute an object's hash. See
		`HashFunc_Object`.
	@param copyFunc Function to copy the object. If the object is immutable,
		set to `nil` so the runtime only retains. If a shallow byte-for-byte
		clone is sufficient, set to `CloneCopyFunc_Object`. See
		`CopyFunc_Object`.
	@param freezeFunc Function to freeze all referenced objects. Set to `nil`
		if the object does not reference other objects. See
		`FreezeFunc_Object`.
	@param destroyFunc Function for extra clean-up before destruction. Set to
		`nil` if no clean-up is needed beyond freeing memory. See
		`DestroyFunc_Object`.
	@param compareFunc Function to compare objects. If a `memcmp()` on the
		object storage is sufficient, set to `nil`. See `CompareFunc_Object`.
	@param createDescFunc Function that creates a human-readable description
		of the object. Useful for logging and debugging. Caller frees the
		returned string. See `CreateDescFunc_Object`.
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
	Increment the object's retain count and return the same pointer.
*/
public
void *_nil retain_Object( void *_nil object );


/**
	Mark the object for copy-on-write on the next modification because an
	immutable reference exists. Does nothing if the object is immutable
	(no `copyFunc`).

	@see ObjectType->copyFunc
*/
public
void *_nil freeze_Object( void *_nil object );


/**
	Balance a previous creation or retain. Destroy the object when the
	retain count reaches zero.
*/
public
void discard_Object( void *_nil object );

/**
	@param size Total size of the object in bytes, including the leading
		`struct Object *` field.
	@param type Pointer to the object's type descriptor.

	@return Pointer to a newly allocated object block. You may cast the
		result to any structure of the requested size, provided the
		structure begins with a field of type `struct Object * <any_name>;`.

	@code
	typedef struct {
		struct Object * objHeader; // Name does not matter
		// String-specific fields follow
	} String;

	String *str = create_Object(sizeof(String), &StringType);
	@endcode

	@note
	All fields are zero-initialized (0, false, nil, etc.).

	@warning
	If the structure ends with a flexible array member
	(e.g. `uint8_t data[];` or `uint8_t data[0];`), include the
	runtime size of that array in `size`.
*/
public
void * create_Object(
	uint16_t size,
	const struct ObjectType * const type
);


// ============================================================================
end_header
#include "end_header.h"