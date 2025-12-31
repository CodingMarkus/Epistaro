#ifdef STRICT_INCLUDE_CHECKS
	#ifndef _beginPtrActive
		#error end_ptr.h included without including begin_ptr.h first
	#endif
#endif
#undef _beginPtrActive

// ============================================================================

#undef OutOpt
#undef OutReq

#undef Opt
#undef _req
#undef _opt
