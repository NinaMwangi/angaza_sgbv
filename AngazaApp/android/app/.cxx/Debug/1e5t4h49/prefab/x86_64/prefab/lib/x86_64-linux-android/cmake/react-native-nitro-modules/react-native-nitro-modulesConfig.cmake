if(NOT TARGET react-native-nitro-modules::NitroModules)
add_library(react-native-nitro-modules::NitroModules SHARED IMPORTED)
set_target_properties(react-native-nitro-modules::NitroModules PROPERTIES
    IMPORTED_LOCATION "/Users/nina/Angaza/new/AngazaApp/node_modules/react-native-nitro-modules/android/build/intermediates/cxx/Debug/6541j6n5/obj/x86_64/libNitroModules.so"
    INTERFACE_INCLUDE_DIRECTORIES "/Users/nina/Angaza/new/AngazaApp/node_modules/react-native-nitro-modules/android/build/headers/nitromodules"
    INTERFACE_LINK_LIBRARIES ""
)
endif()

