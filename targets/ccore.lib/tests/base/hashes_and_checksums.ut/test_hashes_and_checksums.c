#include "base/begin_impl.h"
begin_impl
// ============================================================================

void runAllTests_xxh3( void );

void runAllTests_xxh32( void );

void runAllTests_fletcher32( void );


int main( void )
{
	runAllTests_xxh3();
	runAllTests_xxh32();
	runAllTests_fletcher32();
	return 0;
}

// ============================================================================
end_impl
