#pragma once

#include "begin_header.h"
begin_header
// ============================================================================

/**
	Creates a deep copy.
	Returning a shim object that implements copy-on-write is allowed.
 */
typedef void * (* CopyFunc_Object)( const void * anyObject );

/**
	Compares the object to another one, returns `true` only if both objects are
	functional equivalent in every aspect.
 */
typedef bool (* CompareFunc_Object)( const void *_nil anyObject );

/**
	Performs additional clean-up when an object is about to be destroyed.
 */
typedef void (* DestroyFunc_Object)( const void * anyObject );

/**
	Creates a human readable description string of the object.
	Caller must free returned string.
 */
typedef char * (* CreateDescFunc_Object)( const void * anyObject );


/**
	@param name Name of the object as printable string. For the same object
		type, it's not sufficient that this string has the same "value", it
		actually must be the same string (== comparison must be true!).
	@param copyFunc Function to copy the object. If the object is immutable,
		just set to `nil` and the object is never copied but just retained.
		If the object can be copied by just cloning it byte for byte, set it
		to `CloneCopyFunc_Object`.
	@param destroyFunc Function to perform additional clean-up when the object
		is about to be destroyed. Set it to `nil` if no clean up is required
		other than freeing the object's memory.
	@param compareFunc Function to compare the object. If the object can be
		compared by just using `memcmp()`, set it to `nil`.
	@param createDescFunc Function creates a human readable description of
		the object. Useful for logging and debugging. Caller must free returned
		string.
*/
struct ObjectType {
	const char * name;
	CopyFunc_Object _nil copyFunc;
	DestroyFunc_Object _nil destroyFunc;
	CompareFunc_Object _nil compareFunc;
	CreateDescFunc_Object createDescFunc;
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