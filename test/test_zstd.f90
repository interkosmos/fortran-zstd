! test_zstd.f90
!
! Author:  Philipp Engel
! Licence: ISC
program main
    use, intrinsic :: iso_c_binding
    use :: zstd
    implicit none (type, external)

    integer, parameter :: NTESTS = 2

    integer :: i
    logical :: tests(NTESTS)

    print '("zstd version number: ", i0)', zstd_version_number()
    print '("zstd version string: ", a)',  zstd_version_string()

    tests(1) = test_simple()
    tests(2) = test_simple_multi()

    do i = 1, NTESTS
        if (.not. tests(i)) error stop
    end do
contains
    logical function test_simple() result(success)
        !! Simple API.
        character(len=:), allocatable :: dst1, dst2, src
        integer                       :: level
        integer(kind=c_size_t)        :: dst_len, src_len
        integer(kind=c_size_t)        :: stat

        success = .false.

        print '(">>> test_simple")'

        src = repeat('Now is the time for all good men to come to the aid of the party. ', 128)

        src_len = len(src, kind=c_size_t)
        dst_len = zstd_compress_bound(src_len)

        allocate (character(len=dst_len) :: dst1)
        allocate (character(len=src_len) :: dst2)

        level = zstd_default_c_level()
        stat  = zstd_compress(dst1, dst_len, src, src_len, level)

        if (zstd_is_error(stat)) then
            print '("zstd_compress: ", a)', zstd_get_error_name(stat)
            return
        end if

        dst_len = stat

        print '("src length: ", i0)', src_len
        print '("dst length: ", i0)', dst_len

        stat = zstd_decompress(dst2, src_len, dst1, dst_len)

        if (zstd_is_error(stat)) then
            print '("zstd_decompress: ", a)', zstd_get_error_name(stat)
            return
        end if

        if (dst2 /= src) then
            print '("data mismatch")'
            return
        end if

        success = .true.
    end function test_simple

    logical function test_simple_multi() result(success)
        !! Multiple simple API.
        character(len=:), allocatable :: dst1, dst2, src
        integer                       :: level
        integer(kind=c_size_t)        :: dst_len, src_len
        integer(kind=c_size_t)        :: stat, stat2
        type(c_ptr)                   :: c_ctx, d_ctx

        success = .false.

        print '(">>> test_simple_multi")'

        src = repeat('Now is the time for all good men to come to the aid of the party. ', 128)

        src_len = len(src, kind=c_size_t)
        dst_len = zstd_compress_bound(src_len)

        allocate (character(len=dst_len) :: dst1)
        allocate (character(len=src_len) :: dst2)

        level = zstd_default_c_level()
        c_ctx = zstd_create_c_ctx()
        stat  = zstd_compress_c_ctx(c_ctx, dst1, dst_len, src, src_len, level)
        stat2 = zstd_free_c_ctx(c_ctx)

        if (zstd_is_error(stat)) then
            print '("zstd_compress: ", a)', zstd_get_error_name(stat)
            return
        end if

        dst_len = stat

        print '("src length: ", i0)', src_len
        print '("dst length: ", i0)', dst_len

        d_ctx = zstd_create_d_ctx()
        stat  = zstd_decompress_d_ctx(d_ctx, dst2, src_len, dst1, dst_len)
        stat2 = zstd_free_d_ctx(d_ctx)

        if (zstd_is_error(stat)) then
            print '("zstd_decompress: ", a)', zstd_get_error_name(stat)
            return
        end if

        if (dst2 /= src) then
            print '("data mismatch")'
            return
        end if

        success = .true.
    end function test_simple_multi
end program main
