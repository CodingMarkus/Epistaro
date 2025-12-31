#ifdef _beginPtrActive
	#error begin_ptr.h included twice without including end_ptr.h first
#endif
#define _beginPtrActive

// ============================================================================

#define _opt  _Nullable
#define _req  _Nonnull
#define Opt( type ) type _opt

#define Out( type ) type _req * _req
#define OutOpt( type ) type _opt * _req
