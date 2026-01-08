#include "test/test.h"

#include "native_value.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "base/begin_impl.h"
begin_impl
// ============================================================================

enum { kMaxTestValues = 32 };

static const char kTestValueTypeName[] = "TestValue";

struct TestValueState {
	const NativeValue * value;
	int32e number;
	bool frozen_called;
	sint8e last_copy_is_deep;
};

struct TestValuePayload {
	int32e unused;
};

static struct TestValueState g_test_values[kMaxTestValues];
static int32e g_destroy_count = 0;


static
Opt(struct TestValueState *) findState( const NativeValue * value )
{
	for (init i = 0; i < kMaxTestValues; ++i) {
		if (g_test_values[i].value == value) return &g_test_values[i];
	}
	return nil;
}


static
struct TestValueState * requireState( Opt(const NativeValue *) value )
{
	expect(value, "Missing test value state");
	def required = (const NativeValue *)value;
	def state = findState(required);
	expect(state, "Missing test value state");
	return (struct TestValueState *)state;
}


static
Opt(struct TestValueState *) addState(
	const NativeValue * value, int32e number )
{
	for (init i = 0; i < kMaxTestValues; ++i) {
		if (g_test_values[i].value) continue;
		g_test_values[i].value = value;
		g_test_values[i].number = number;
		g_test_values[i].frozen_called = false;
		g_test_values[i].last_copy_is_deep = -1;
		return &g_test_values[i];
	}
	expect(false, "Test value capacity exceeded");
	return nil;
}


static
void removeState( const NativeValue * value )
{
	def state = requireState(value);
	*state = (struct TestValueState){ 0 };
}


static
int countStates( void )
{
	init count = 0;
	for (init i = 0; i < kMaxTestValues; ++i) {
		if (g_test_values[i].value) count++;
	}
	return count;
}


static
void hashTestValue(
	const NativeValue * value,
	Hasher * hasher, const HasherInterface hasherIntf )
{
	def state = requireState(value);
	hasherIntf.addBytes(hasher, &state->number, sizeof(state->number));
}


static
bool equalTestValue(
	const NativeValue * value, const NativeValue * otherValue )
{
	def state = requireState(value);
	def other = requireState(otherValue);
	return state->number == other->number;
}


static
void freezeTestValue( Opt(NativeValue *) value )
{
	if (!value) return;
	def state = requireState(value);
	state->frozen_called = true;
}


static const struct TypeDescriptor_NativeValue TestValueType;

static
void * copyTestValue(
	const NativeValue * value, bool copyIsDeep )
{
	def state = requireState(value);
	def copy = create_NativeValue(
		true, sizeof(struct TestValuePayload), &TestValueType);
	expect(copy, "create_NativeValue failed in copy");
	def copyState = addState(copy, state->number);
	expect(copyState, "Test value capacity exceeded");
	((struct TestValueState *)copyState)->last_copy_is_deep =
		copyIsDeep ? 1 : 0;
	return copy;
}


static
void destroyTestValue( const NativeValue * value )
{
	removeState(value);
	g_destroy_count++;
}


static
char * createDescTestValue( const NativeValue * value )
{
	def state = requireState(value);
	init len = snprintf(
		nil, 0, "%s(%d)", kTestValueTypeName, (int)state->number);
	expect(len >= 0, "snprintf failed");
	init desc = malloc((size_t)len + 1u);
	expect(desc, "malloc failed");
	snprintf(desc, (size_t)len + 1u, "%s(%d)",
		kTestValueTypeName, (int)state->number);
	return desc;
}


static const struct TypeDescriptor_NativeValue TestValueType = {
	.name = kTestValueTypeName,
	.hashFunc = hashTestValue,
	.copyFunc = copyTestValue,
	.equalFunc = equalTestValue,
	.createDescFunc = createDescTestValue,
	.freezeFunc = freezeTestValue,
	.destroyFunc = destroyTestValue,
};


static
NativeValue * createTestValue( int32e number, bool immutable )
{
	def value = create_NativeValue(
		immutable, sizeof(struct TestValuePayload), &TestValueType);
	expect(value, "create_NativeValue failed");
	expect(addState(value, number), "Test value capacity exceeded");
	return value;
}


static
void test_basics( void )
{
	def value = createTestValue(42, true);

	def name = getName_NativeValue(value);
	expect(strcmp(name, kTestValueTypeName) == 0,
		"getName_NativeValue returned wrong name");

	def desc = createDescription_NativeValue(value);
	expect(strcmp(desc, "TestValue(42)") == 0,
		"createDescription_NativeValue returned wrong description");
	free((void *)desc);

	discard_NativeValue(value);
}


static
void test_hashAndEqual( void )
{
	def value1 = createTestValue(7, true);
	def value2 = createTestValue(7, true);
	def value3 = createTestValue(11, true);

	expect(isEqual_NativeValue(value1, value2));
	expect(!isEqual_NativeValue(value1, value3));
	expect(!isEqual_NativeValue(value1, nil));
	expect(!isEqual_NativeValue(nil, value2));

	def hash1 = hash_NativeValue(value1);
	def hash2 = hash_NativeValue(value2);
	def hash3 = hash_NativeValue(value3);

	expect(hash1 == hash2);
	expect(hash1 != hash3);
	expect(hash_NativeValue(nil) == 0);

	def hashIntf = getDefaultHasherInterface_Hasher();
	int8e hasherStorage1[hashIntf->getRequiredSize()];
	def hasher1 = hashIntf->initStorage(hasherStorage1);
	hashWithHasher_NativeValue(value1, hasher1, hashIntf);
	def hashWith = hashIntf->finalize(hasher1);

	int8e hasherStorage2[hashIntf->getRequiredSize()];
	def hasher2 = hashIntf->initStorage(hasherStorage2);
	hashTestValue(value1, hasher2, *hashIntf);
	def hashDirect = hashIntf->finalize(hasher2);

	expect(hashWith == hashDirect);

	discard_NativeValue(value1);
	discard_NativeValue(value2);
	discard_NativeValue(value3);
}


static
void test_copyAndFreeze( void )
{
	def value = createTestValue(100, false);

	def shallow = copy_NativeValue(value, false);
	expect(shallow != value);
	expect(isEqual_NativeValue(value, shallow));
	expect(requireState(shallow)->last_copy_is_deep == 0);

	def deep = copy_NativeValue(value, true);
	expect(deep != value);
	expect(isEqual_NativeValue(value, deep));
	expect(requireState(deep)->last_copy_is_deep == 1);

	def state = requireState(value);
	expect(!state->frozen_called);
	freeze_NativeValue(value);
	expect(state->frozen_called);

	def unfrozen = unfreeze_NativeValue(value);
	expect(unfrozen != value);
	expect(isEqual_NativeValue(value, unfrozen));

	init slot = createTestValue(200, false);
	freeze_NativeValue(slot);
	expect(unfreezeInPlace_NativeValue(&slot));
	discard_NativeValue(slot);

	def retainable = createTestValue(300, false);
	def retained = unfreeze_NativeValue(retainable);
	expect(retained == retainable);
	discard_NativeValue(retained);
	discard_NativeValue(retainable);

	discard_NativeValue(value);
	discard_NativeValue(shallow);
	discard_NativeValue(deep);
	discard_NativeValue(unfrozen);
}


static
void test_retainAndDiscard( void )
{
	def initialDestroy = g_destroy_count;
	def value = createTestValue(5, true);
	def retained = retain_NativeValue(value);
	expect(retained == value);
	discard_NativeValue(retained);
	expect(g_destroy_count == initialDestroy);
	discard_NativeValue(value);
	expect(g_destroy_count == initialDestroy + 1);
}


static
void test_setters( void )
{
	init slot = createTestValue(1, true);
	def value2 = createTestValue(2, true);

	expect(!set_NativeValue(&slot, slot));
	expect(set_NativeValue(&slot, value2));

	discard_NativeValue(value2);
	discard_NativeValue(slot);

	def value3 = createTestValue(3, true);
	init opt = (NativeValue *)nil;
	expect(setOpt_NativeValue(&opt, value3));
	expect(opt == value3);
	expect(setOpt_NativeValue(&opt, nil));
	expect(!opt);
	discard_NativeValue(value3);

	init optValue = (NativeValue *)nil;
	expect(!setOpt_NativeValue(&optValue, nil));
	expect(!unfreezeInPlaceOpt_NativeValue(&optValue));
}


int main( void )
{
	test_basics();
	test_hashAndEqual();
	test_copyAndFreeze();
	test_retainAndDiscard();
	test_setters();

	expect(countStates() == 0, "Leaked test values");
	return 0;
}

// ============================================================================
end_impl
