set(FOLDER_NAME be_cuda)
set(SUBDIRECTORIES)
set(SRC_FILES
        main.cu
        be_cuda_benchmark.cu
)
set(HEADER_FILES
        be_cuda_benchmark.h
)
set(TEST_FILES)
set(EXTRA_FILES)

if (${HMARK_BUILD_CUDA})
    add_executable(${FOLDER_NAME} ${HEADER_FILES} ${SRC_FILES})
    target_link_libraries(${FOLDER_NAME}
            be time_measurement command_line_option benchmark ${OpenCV_LIBS})
    if (HMARK_HIPCPU_VECZ_WIDTH_32)
        target_compile_options(${FOLDER_NAME} PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:-hipcpu-vecz-width=32>)
    endif ()
endif ()

