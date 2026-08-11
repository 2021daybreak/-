cmake_minimum_required(VERSION 3.16)

project(server_test VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Network)

qt_standard_project_setup(REQUIRES 6.10)

# Content of downloaded design from Figma to Qt or similar
if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/importedcontent/CMakeLists.txt")
    add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/importedcontent)
endif()

qt_add_executable(appserver_test
    main.cpp
)

qt_add_qml_module(appserver_test
    URI server_test
    QML_FILES
        Main.qml
    SOURCES
        tcpclient.h
        tcpclient.cpp
        ImageProcessor.h
        ImageProcessor.cpp
    RESOURCES
        resource.qrc
        SOURCES
        SOURCES mapimageprovider.h mapimageprovider.cpp
        SOURCES sshmanager.h sshmanager.cpp
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appserver_test PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appserver_test
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appserver_test
    PRIVATE Qt6::Quick
            Qt6::Network
)
#添加QSsh的头文件路径
#源码目录
include_directories("C:/Users/sz/Documents/server_test/qssh")
target_link_libraries(appserver_test PRIVATE
"C:/Users/sz/Documents/server_test/lib/QSsh.dll")