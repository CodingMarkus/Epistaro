#ifdef _beginPtrActive
	#error begin_ptr.h included twice without including end_ptr.h first
#endif
#define _beginPtrActive

// ============================================================================

#define _opt  _Nullable
#define _req  _Nonnull
#define Opt( type ) type _opt

#define OutPtr( type ) type _req * _req
#define OutPtrOpt( type ) type _opt * _req
#define OptOutPtr( type ) type _req * _opt
#define OptOutPtrOpt( type ) type _opt * _opt

#define PtrArrayOf( type ) const type _req [] _req
#define OptPtrArrayOf( type ) const type _req [] _opt
#define PtrArrayOfOpt( type ) const type _opt [] _req
#define OptPtrArrayOfOpt( type ) const type _opt [] _opt
