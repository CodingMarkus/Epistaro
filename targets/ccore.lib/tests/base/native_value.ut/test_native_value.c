#include "test/test.h"

#include "native_value.h"

#include <stdlib.h>
#include <string.h>

#include "base/begin_impl.h"
begin_impl
// ============================================================================

struct TestValuePayload {
	int32e payloadValue;
};

static const struct TypeDescriptor_NativeValue TestValueType;
static sint8e g_last_copy_is_deep = -1;
static int32e g_copy_count = 0;

static
void hashTestValue(
	const NativeValue * value,
	Hasher * hasher, const HasherInterface hasherIntf )
{
	(void)value;
	(void)hasher;
	(void)hasherIntf;
}


static
bool equalTestValue(
	const NativeValue * value, const NativeValue * otherValue )
{
	(void)value;
	(void)otherValue;
	return true;
}


static
void freezeTestValue( Opt(NativeValue *) value )
{
	(void)value;
}


static
void * copyTestValue(
	const NativeValue * value, bool copyIsDeep )
{
	(void)value;
	g_last_copy_is_deep = copyIsDeep ? 1 : 0;
	g_copy_count++;
	return create_NativeValue(
		false, sizeof(struct TestValuePayload), &TestValueType);
}


static
void destroyTestValue( const NativeValue * value )
{
	(void)value;
}


static
char * createDescTestValue( const NativeValue * value )
{
	(void)value;
	return strdup("TestValue");
}


static const struct TypeDescriptor_NativeValue TestValueType = {
	.name = "TestValue",
	.hashFunc = hashTestValue,
	.copyFunc = copyTestValue,
	.equalFunc = equalTestValue,
	.createDescFunc = createDescTestValue,
	.freezeFunc = freezeTestValue,
	.destroyFunc = destroyTestValue,
};


static
bool writeStoragePayload(
	void * storage, intS size, void * context )
{
	expect(size == (intS)sizeof(struct TestValuePayload));
	def payload = (struct TestValuePayload *)storage;
	payload->payloadValue = *(int32e *)context;
	return true;
}


static
void test_mutableStorageRequiresMutable( void )
{
	init immutable = create_NativeValue(
		true, sizeof(struct TestValuePayload), &TestValueType);
	init writeValue = 1;
	expect_require("!header->immutableFlag", {
		withMutableStorage_NativeValue(
			&immutable, writeStoragePayload, &writeValue);
	});
	discard_NativeValue(immutable);
}

static
void test_frozenMutableStorageUsesShallowCopy( void )
{
	init value = create_NativeValue(
		false, sizeof(struct TestValuePayload), &TestValueType);
	init writeValue = 1;
	g_last_copy_is_deep = -1;
	g_copy_count = 0;

	freeze_NativeValue(value);
	expect(withMutableStorage_NativeValue(
		&value, writeStoragePayload, &writeValue));
	expect(g_copy_count == 1);
	expect(g_last_copy_is_deep == 0);
	discard_NativeValue(value);

	init optValue = create_NativeValue(
		false, sizeof(struct TestValuePayload), &TestValueType);
	writeValue = 2;
	g_last_copy_is_deep = -1;
	g_copy_count = 0;

	freeze_NativeValue(optValue);
	expect(withMutableStorageOpt_NativeValue(
		&optValue, writeStoragePayload, &writeValue));
	expect(g_copy_count == 1);
	expect(g_last_copy_is_deep == 0);
	discard_NativeValue(optValue);
}


int main( void )
{
	test_mutableStorageRequiresMutable();
	test_frozenMutableStorageUsesShallowCopy();
	return 0;
}

// ============================================================================
end_impl
