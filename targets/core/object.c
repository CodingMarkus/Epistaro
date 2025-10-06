#include "object.h"

#include <stdalign.h>

#include "begin_impl.h"
begin_impl
// ============================================================================

struct Object {
	const struct ObjectType * type;
	uint_fast32_t refCount;
	// Checksum is only 15 bits.
	// The highest bit is the COW flag.
	uint_fast16_t checksum;
	uint_fast16_t size;
};


struct Fletcher16State {
	uint_fast16_t s1, s2;
};

// ----------------------------------------------------------------------------

static
struct Fletcher16State fletcher16Update(
	struct Fletcher16State state, const void * data, size_t len )
{
    const unsigned char * p = data;
    while (len--){
        state.s1 += *p++;
		if (state.s1 >= 255) state.s1 -= 255;
        state.s2 += state.s1;
		if (state.s2 >= 255) state.s2 -= 255;
    }
	return state;
}


static inline
uint16_t fletcher16Finalize( const struct Fletcher16State state )
{
	return (uint16_t)((state.s2 << 8) | state.s1);
}


static inline
uint16_t calcObjectChecksum( struct Object * object )
{
#define f16feed( state, value )                  \
	({                                           \
		def _tmp = (value);                      \
		def _size = sizeof(_tmp);                \
		fletcher16Update((state), &_tmp, _size); \
	})

	struct Fletcher16State fstate = { 0 };
	fstate = f16feed(fstate, object->size);
	fstate = f16feed(fstate, (const void *)object->type);
	fstate = f16feed(fstate, (const void *)object->type->name);

#undef f16feed
	return fletcher16Finalize(fstate);
}


static inline
void assertIsObject( void * ptr )
{
#if DEBUGGING || TESTING
	def object = *(struct Object **)ptr;
	assert(
		(calcObjectChecksum(object) & 0x7FFF)
		== (object->checksum & 0x7FFF)
	);
#else
	(void)ptr;
#endif
}


static inline
bool objIsCOW( struct Object * object )
{
	return (object->checksum >> 15);
}


static inline
void setIsCOW( struct Object * object )
{
	object->checksum |= 0x8000;
}


static inline
void unsetIsCOW( struct Object * object )
{
	object->checksum &= ~0x8000;
}

// ----------------------------------------------------------------------------

void *_nil retain_Object( void *_nil maybePtr )
{
	guard_def (ptr, maybePtr) {
		assertIsObject(ptr);
		def object = *(struct Object **)ptr;
		assert(object->refCount >= 1);
		assert(object->refCount < UINT_FAST32_MAX);
		object->refCount++;
	}
	return maybePtr;
}


void *_nil freeze_Object( void *_nil maybePtr )
{
	guard_def (ptr, maybePtr) {
		assertIsObject(ptr);
		def object = *(struct Object **)ptr;
		assert(object->refCount >= 1);
		if (object->type->copyFunc) setIsCOW(object);
	}
	return maybePtr;
}


void discard_Object( void *_nil maybePtr )
{
	guard_def (ptr, maybePtr) { } else { return; }
	assertIsObject(ptr);
	def object = *(struct Object **)ptr;
	assert(object->refCount >= 1);
	switch (--object->refCount) {
		case 0: break; // continue below
		case 1: unsetIsCOW(object); return;
	 	default: return;
	}
	if (object->type->destroyFunc) object->type->destroyFunc(ptr);
	free(ptr);
}



void * create_Object(
	uint16_t size,
	const struct ObjectType * const type )
{
	assert(size >= sizeof(struct Object *));
	def objectAlignment = alignof(struct Object);
	def alignedSize =
		(size + objectAlignment - 1) & ~(objectAlignment - 1);
	def totalSize = alignedSize + sizeof(struct Object);

	assert(totalSize <= UINT16_MAX);
	def result = calloc(1, totalSize);

	def object = (struct Object *)((uint8_t *)result + alignedSize);
    *(struct Object **)result = object;

	object->type = type;
	object->refCount = 1;
	object->size = alignedSize;

#if DEBUGGING || TESTING
	object->checksum = calcObjectChecksum(object) & 0x7FFF;
#else
	object->checksum = 0;
#endif

	return result;
}

// ============================================================================
end_impl