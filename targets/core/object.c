#include "object.h"

#include "fletcher32.h"

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

static inline
uint32_t calcObjectChecksum( struct Object *object )
{
#define f32feed(state, value) ({ \
    def _tmp = (value); \
    def _size = sizeof(_tmp); \
    Fletcher32Update((state), &_tmp, _size); \
})

    struct Fletcher32State st = { 0 };
    st = f32feed(st, object->size);
    st = f32feed(st, (const void *)object->type);
    st = f32feed(st, (const void *)object->type->name);

#undef f32feed
    return Fletcher32Finalize(st);
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