include( "gap.jl" )
gc_enable(false)

function from_gap_int16(obj :: GapObj) :: Int16
    x = libgap_Int_IntObj( obj )
    return Int16(x)
end

function from_gap_int32(obj :: GapObj) :: Int32
    x = libgap_Int_IntObj( obj )
    return Int32(x)
end

from_gap_int64(obj :: GapObj) = libgap_Int_IntObj(obj)

from_gap_string(obj :: GapObj) = libgap_String_StringObj(obj)

function from_gap_list( obj :: GapObj) :: Array{GapObj}
    len = from_gap_int64( libgap_LenPlist( obj ) )
    array = Array{GapObj}(len)
    for i in 1:len
        array[i] = libgap_ElmPlist(list,i)
    end
    return array
end

function from_gap_list_type( obj :: GapObj, element_type :: DataType ) :: Array{Int64}
    converted_list = from_gap_list( obj )
    len_list = length(converted_list)
    new_array = Array{element_type}(len_list)
    for i in 1:len_list
        new_array[ i ] = from_gap(len_list,element_type)
    end
    return new_array
end


