# An instruction builder represents a point within a basic block and is the exclusive means
# of building instructions using the C interface.

export Builder,
       position!,
       debuglocation, debuglocation!

import Base: position, insert!

@reftypedef ref=LLVMBuilderRef immutable Builder end

Builder() = Builder(API.LLVMCreateBuilder())
Builder(ctx::Context) = Builder(API.LLVMCreateBuilderInContext(ref(ctx)))

dispose(builder::Builder) = API.LLVMDisposeBuilder(ref(builder))

function Builder(f::Core.Function, args...)
    builder = Builder(args...)
    try
        f(builder)
    finally
        dispose(builder)
    end
end

position(builder::Builder) = BasicBlock(API.LLVMGetInsertBlock(ref(builder)))
position!(builder::Builder, inst::Instruction) =
    API.LLVMPositionBuilderBefore(ref(builder), ref(inst))
position!(builder::Builder, bb::BasicBlock) =
    API.LLVMPositionBuilderAtEnd(ref(builder), blockref(bb))
position!(builder::Builder) = API.LLVMClearInsertionPosition(ref(builder))

insert!(builder::Builder, inst::Instruction) =
    API.LLVMInsertIntoBuilder(ref(builder), ref(inst))
insert!(builder::Builder, inst::Instruction, name::String) =
    API.LLVMInsertIntoBuilderWithName(ref(builder), ref(inst), name)

debuglocation(builder::Builder) =
    MetadataAsValue(API.LLVMGetCurrentDebugLocation(ref(builder)))
debuglocation!(builder::Builder) =
    API.LLVMSetCurrentDebugLocation(ref(builder), ref(Value, C_NULL))
debuglocation!(builder::Builder, loc::MetadataAsValue) =
    API.LLVMSetCurrentDebugLocation(ref(builder), ref(loc))
debuglocation!(builder::Builder, inst::Instruction) =
    API.LLVMSetInstDebugLocation(ref(builder), ref(inst))


## build methods

# TODO/IDEAS:
# - dynamic dispatch based on `llvmtype` (eg. disambiguating `add!` and `fadd!`)
# - auto `ref(...)` using `@generated deref` for API calling
#   (cfr. `cconvert` for `ccall`)

export ret!, br!, switch!, indirectbr!, invoke!, resume!, unreachable!,

       binop!, add!, nswadd!, nuwadd!, fadd!, sub!, nswsub!, nuwsub!, fsub!, mul!, nswmul!,
       nuwmul!, fmul!, udiv!, sdiv!, exactsdiv!, fdiv!, urem!, srem!, frem!, neg!, nswneg!,
       nuwneg!, fneg!,

       shl!, lshr!, ashr!, and!, or!, xor!, not!,

       extract_element!, insert_element!, shuffle_vector!,

       extract_value!, insert_value!,

       alloca!, array_alloca!, malloc!, array_malloc!, free!, load!, store!, fence!,
       atomic_rmw!, atomic_cmpxchg!, gep!, inbounds_gep!, struct_gep!,

       trunc!, zext!, sext!, fptoui!, fptosi!, uitofp!, sitofp!, fptrunc!, fpext!,
       ptrtoint!, inttoptr!, bitcast!, addrspacecast!, zextorbitcast!, sextorbitcast!,
       truncorbitcast!, cast!, pointercast!, intcast!, fpcast!,

       icmp!, fcmp!, phi!, select!, call!, va_arg!, landingpad!,

       globalstring!, globalstring_ptr!, isnull!, isnotnull!, ptrdiff!


# terminator instructions

ret!(builder::Builder) =
    Instruction(API.LLVMBuildRetVoid(ref(builder)))

ret!(builder::Builder, V::Value) =
    Instruction(API.LLVMBuildRet(ref(builder), ref(V)))

ret!{T<:Value}(builder::Builder, RetVals::Vector{T}) =
    Instruction(API.LLVMBuildAggregateRet(ref(builder), ref.(RetVals), Cuint(length(RetVals))))

br!(builder::Builder, Dest::BasicBlock) =
    Instruction(API.LLVMBuildBr(ref(builder), blockref(Dest)))

br!(builder::Builder, If::Value, Then::BasicBlock, Else::BasicBlock) =
    Instruction(API.LLVMBuildCondBr(ref(builder), ref(If), blockref(Then), blockref(Else)))

switch!(builder::Builder, V::Value, Else::BasicBlock, NumCases::Integer=10) =
    Instruction(API.LLVMBuildSwitch(ref(builder), ref(V), blockref(Else), Cuint(NumCases)))

indirectbr!(builder::Builder, Addr::Value, NumDests::Integer=10) =
    Instruction(API.LLVMBuildIndirectBr(ref(builder), ref(Addr), Cuint(NumDests)))

invoke!{T<:Value}(builder::Builder, Fn::Value, Args::Vector{T}, Then::BasicBlock, Catch::BasicBlock, Name::String="") =
    Instruction(API.LLVMBuildInvoke(ref(builder), ref(Fn), ref.(Args), Cuint(length(Args)), blockref(Then), blockref(Catch), Name))

resume!(builder::Builder, Exn::Value) =
    Instruction(API.LLVMBuildResume(ref(builder), ref(Exn)))

unreachable!(builder::Builder) =
    Instruction(API.LLVMBuildUnreachable(ref(builder)))


# binary operations

binop!(builder::Builder, Op::API.LLVMOpcode, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildBinOp(ref(builder), Op, ref(LHS), ref(RHS), Name))

add!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildAdd(ref(builder), ref(LHS), ref(RHS), Name))

nswadd!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildNSWAdd(ref(builder), ref(LHS), ref(RHS), Name))

nuwadd!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildNUWAdd(ref(builder), ref(LHS), ref(RHS), Name))

fadd!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildFAdd(ref(builder), ref(LHS), ref(RHS), Name))

sub!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildSub(ref(builder), ref(LHS), ref(RHS), Name))

nswsub!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildNSWSub(ref(builder), ref(LHS), ref(RHS), Name))

nuwsub!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildNUWSub(ref(builder), ref(LHS), ref(RHS), Name))

fsub!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildFSub(ref(builder), ref(LHS), ref(RHS), Name))

mul!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildMul(ref(builder), ref(LHS), ref(RHS), Name))

nswmul!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildNSWMul(ref(builder), ref(LHS), ref(RHS), Name))

nuwmul!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildNUWMul(ref(builder), ref(LHS), ref(RHS), Name))

fmul!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildFMul(ref(builder), ref(LHS), ref(RHS), Name))

udiv!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildUDiv(ref(builder), ref(LHS), ref(RHS), Name))

sdiv!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildSDiv(ref(builder), ref(LHS), ref(RHS), Name))

exactsdiv!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildExactSDiv(ref(builder), ref(LHS), ref(RHS), Name))

fdiv!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildFDiv(ref(builder), ref(LHS), ref(RHS), Name))

urem!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildURem(ref(builder), ref(LHS), ref(RHS), Name))

srem!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildSRem(ref(builder), ref(LHS), ref(RHS), Name))

frem!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildFRem(ref(builder), ref(LHS), ref(RHS), Name))


# bitwise binary operations

shl!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildShl(ref(builder), ref(LHS), ref(RHS), Name))

lshr!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildLShr(ref(builder), ref(LHS), ref(RHS), Name))

ashr!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildAShr(ref(builder), ref(LHS), ref(RHS), Name))

and!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildAnd(ref(builder), ref(LHS), ref(RHS), Name))

or!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildOr(ref(builder), ref(LHS), ref(RHS), Name))

xor!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildXor(ref(builder), ref(LHS), ref(RHS), Name))


# vector operations

extract_element!(builder::Builder, VecVal::Value, Index::Value, Name::String="") =
    Instruction(API.LLVMBuildExtractElement(ref(builder), ref(VecVal), ref(Index), Name))

insert_element!(builder::Builder, VecVal::Value, EltVal::Value, Index::Value, Name::String="") =
    Instruction(API.LLVMBuildInsertElement(ref(builder), ref(VecVal), ref(EltVal), ref(Index), Name))

shuffle_vector!(builder::Builder, V1::Value, V2::Value, Mask::Value, Name::String="") =
    Instruction(API.LLVMBuildShuffleVector(ref(builder), ref(V1), ref(V2), ref(Mask), Name))


# aggregate operations

extract_value!(builder::Builder, AggVal::Value, Index, Name::String="") =
    Instruction(API.LLVMBuildExtractValue(ref(builder), ref(AggVal), Cuint(Index), Name))

insert_value!(builder::Builder, AggVal::Value, EltVal::Value, Index, Name::String="") =
    Instruction(API.LLVMBuildInsertValue(ref(builder), ref(AggVal), ref(EltVal), Cuint(Index), Name))


# memory access and addressing operations

alloca!(builder::Builder, Ty::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildAlloca(ref(builder), ref(Ty), Name))

array_alloca!(builder::Builder, Ty::LLVMType, Val::Value, Name::String="") =
    Instruction(API.LLVMBuildArrayAlloca(ref(builder), ref(Ty), ref(Val), Name))

malloc!(builder::Builder, Ty::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildMalloc(ref(builder), ref(Ty), Name))

array_malloc!(builder::Builder, Ty::LLVMType, Val::Value, Name::String="") =
    Instruction(API.LLVMBuildArrayMalloc(ref(builder), ref(Ty), ref(Val), Name))

free!(builder::Builder, PointerVal::Value) =
    Instruction(API.LLVMBuildFree(ref(builder), ref(PointerVal)))

load!(builder::Builder, PointerVal::Value, Name::String="") =
    Instruction(API.LLVMBuildLoad(ref(builder), ref(PointerVal), Name))

store!(builder::Builder, Val::Value, Ptr::Value) =
    Instruction(API.LLVMBuildStore(ref(builder), ref(Val), ref(Ptr)))

fence!(builder::Builder, ordering::API.LLVMAtomicOrdering, singleThread::Bool=false, Name::String="") =
    Instruction(API.LLVMBuildFence(ref(builder), ordering, BoolToLLVM(singleThread), Name))

atomic_rmw!(builder::Builder, op::API.LLVMAtomicRMWBinOp, PTR::Value, Val::Value, ordering::API.LLVMAtomicOrdering, singleThread::Bool) =
    Instruction(API.LLVMBuildAtomicRMW(ref(builder), op, ref(PTR), ref(Val), ordering, BoolToLLVM(singleThread)))

atomic_cmpxchg!(builder::Builder, Ptr::Value, Cmp::Value, New::Value, SuccessOrdering::API.LLVMAtomicOrdering, FailureOrdering::API.LLVMAtomicOrdering, SingleThread::Bool) =
    Instruction(API.LLVMBuildAtomicCmpXchg(ref(builder), ref(Ptr), ref(Cmp), ref(New), SuccessOrdering,FailureOrdering, BoolToLLVM(SingleThread)))

gep!{T<:Value}(builder::Builder, Pointer::Value, Indices::Vector{T}, Name::String="") =
    Instruction(API.LLVMBuildGEP(ref(builder), ref(Pointer), ref.(Indices), Cuint(length(Indices)), Name))

inbounds_gep!{T<:Value}(builder::Builder, Pointer::Value, Indices::Vector{T}, Name::String="") =
    Instruction(API.LLVMBuildInBoundsGEP(ref(builder), ref(Pointer), ref.(Indices), Cuint(length(Indices)), Name))

struct_gep!(builder::Builder, Pointer::Value, Idx, Name::String="") =
    Instruction(API.LLVMBuildStructGEP(ref(builder), ref(Pointer), Cuint(Idx), Name))


# conversion operations

trunc!(builder::Builder, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildTrunc(ref(builder), ref(Val), ref(DestTy), Name))

zext!(builder::Builder, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildZExt(ref(builder), ref(Val), ref(DestTy), Name))

sext!(builder::Builder, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildSExt(ref(builder), ref(Val), ref(DestTy), Name))

fptoui!(builder::Builder, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildFPToUI(ref(builder), ref(Val), ref(DestTy), Name))

fptosi!(builder::Builder, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildFPToSI(ref(builder), ref(Val), ref(DestTy), Name))

uitofp!(builder::Builder, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildUIToFP(ref(builder), ref(Val), ref(DestTy), Name))

sitofp!(builder::Builder, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildSIToFP(ref(builder), ref(Val), ref(DestTy), Name))

fptrunc!(builder::Builder, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildFPTrunc(ref(builder), ref(Val), ref(DestTy), Name))

fpext!(builder::Builder, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildFPExt(ref(builder), ref(Val), ref(DestTy), Name))

ptrtoint!(builder::Builder, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildPtrToInt(ref(builder), ref(Val), ref(DestTy), Name))

inttoptr!(builder::Builder, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildIntToPtr(ref(builder), ref(Val), ref(DestTy), Name))

bitcast!(builder::Builder, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildBitCast(ref(builder), ref(Val), ref(DestTy), Name))

addrspacecast!(builder::Builder, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildAddrSpaceCast(ref(builder), ref(Val), ref(DestTy), Name))

zextorbitcast!(builder::Builder, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildZExtOrBitCast(ref(builder), ref(Val), ref(DestTy), Name))

sextorbitcast!(builder::Builder, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildSExtOrBitCast(ref(builder), ref(Val), ref(DestTy), Name))

truncorbitcast!(builder::Builder, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildTruncOrBitCast(ref(builder), ref(Val), ref(DestTy), Name))

cast!(builder::Builder, Op::API.LLVMOpcode, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildCast(ref(builder), Op, ref(Val), ref(DestTy), Name))

pointercast!(builder::Builder, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildPointerCast(ref(builder), ref(Val), ref(DestTy), Name))

intcast!(builder::Builder, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildIntCast(ref(builder), ref(Val), ref(DestTy), Name))

fpcast!(builder::Builder, Val::Value, DestTy::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildFPCast(ref(builder), ref(Val), ref(DestTy), Name))


# other operations

icmp!(builder::Builder, Op::API.LLVMIntPredicate, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildICmp(ref(builder), Op, ref(LHS), ref(RHS), Name))

fcmp!(builder::Builder, Op::API.LLVMRealPredicate, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildFCmp(ref(builder), Op, ref(LHS), ref(RHS), Name))

phi!(builder::Builder, Ty::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildPhi(ref(builder), ref(Ty), Name))

select!(builder::Builder, If::Value, Then::Value, Else::Value, Name::String="") =
    Instruction(API.LLVMBuildSelect(ref(builder), ref(If), ref(Then), ref(Else), Name))

call!{T<:Value}(builder::Builder, Fn::Value, Args::Vector{T}=Value[], Name::String="") =
    Instruction(API.LLVMBuildCall(ref(builder), ref(Fn), ref.(Args), Cuint(length(Args)), Name))

va_arg!(builder::Builder, List::Value, Ty::LLVMType, Name::String="") =
    Instruction(API.LLVMBuildVAArg(ref(builder), ref(List), ref(Ty), Name))

landingpad!(builder::Builder, Ty::LLVMType, PersFn::Value, NumClauses::Integer, Name::String="") =
    Instruction(API.LLVMBuildLandingPad(ref(builder), ref(Ty), ref(PersFn), Cuint(NumClauses), Name))

neg!(builder::Builder, V::Value, Name::String="") =
    Instruction(API.LLVMBuildNeg(ref(builder), ref(V), Name))

nswneg!(builder::Builder, V::Value, Name::String="") =
    Instruction(API.LLVMBuildNSWNeg(ref(builder), ref(V), Name))

nuwneg!(builder::Builder, V::Value, Name::String="") =
    Instruction(API.LLVMBuildNUWNeg(ref(builder), ref(V), Name))

fneg!(builder::Builder, V::Value, Name::String="") =
    Instruction(API.LLVMBuildFNeg(ref(builder), ref(V), Name))

not!(builder::Builder, V::Value, Name::String="") =
    Instruction(API.LLVMBuildNot(ref(builder), ref(V), Name))


# other build methods

globalstring!(builder::Builder, Str::String, Name::String="") =
    GlobalVariable(API.LLVMBuildGlobalString(ref(builder), Str, Name))

globalstring_ptr!(builder::Builder, Str::String, Name::String="") =
    Instruction(API.LLVMBuildGlobalStringPtr(ref(builder), Str, Name))

isnull!(builder::Builder, Val::Value, Name::String="") =
    Instruction(API.LLVMBuildIsNull(ref(builder), ref(Val), Name))

isnotnull!(builder::Builder, Val::Value, Name::String="") =
    Instruction(API.LLVMBuildIsNotNull(ref(builder), ref(Val), Name))

ptrdiff!(builder::Builder, LHS::Value, RHS::Value, Name::String="") =
    Instruction(API.LLVMBuildPtrDiff(ref(builder), ref(LHS), ref(RHS), Name))
