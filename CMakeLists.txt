# Check http://webdev.elementaryos.org/docs/developer-guide/cmake for documentation

project (super-wingpanel)
cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.8)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

#
# Base bits
#

enable_testing ()

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/super-wingpanel")
set (GETTEXT_PACKAGE "super-wingpanel")
set (EXEC_NAME "super-wingpanel")
set (RELEASE_NAME "Luna")
set (VERSION "0.2.3")
set (VERSION_INFO "luna")
set (CMAKE_C_FLAGS "-ggdb")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (DOLLAR "$")

# Add 'make dist' command for creating release tarball
set (CPACK_PACKAGE_VERSION ${VERSION})
set (CPACK_SOURCE_GENERATOR "TGZ")
set (CPACK_SOURCE_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}-${CPACK_PACKAGE_VERSION}")
set (CPACK_SOURCE_IGNORE_FILES "/build/;/.bzr/;/.bzrignore;~$;${CPACK_SOURCE_IGNORE_FILES}")

include (CPack)
add_custom_target (dist COMMAND ${CMAKE_MAKE_PROGRAM} package_source)

# Set dependencies
set (WINGPANEL_DEPS 
    gobject-2.0
    glib-2.0
    gio-2.0
    gee-1.0
    gdk-x11-3.0
    x11
    gtk+-3.0
    granite
    libwnck-3.0
)

set (WINGPANEL_DEPS_NOVALA 
    gthread-2.0
    indicator3-0.4
)


find_package (PkgConfig)
pkg_check_modules (DEPS REQUIRED ${WINGPANEL_DEPS})
pkg_check_modules (DEPS_NOVALA REQUIRED ${WINGPANEL_DEPS_NOVALA})

# Static Files
file (GLOB desktop_entry "${CMAKE_CURRENT_SOURCE_DIR}/data/super-wingpanel.desktop")
file (GLOB icon "${CMAKE_CURRENT_SOURCE_DIR}/data/super-wingpanel.svg")
file (GLOB icon_close "${CMAKE_CURRENT_SOURCE_DIR}/data/window-close.svg")
file (GLOB icon_unmax "${CMAKE_CURRENT_SOURCE_DIR}/data/window-unmaximize.svg")

# Find the Indicator Directory
execute_process (COMMAND ${PKG_CONFIG_EXECUTABLE} indicator3-0.4 --variable=indicatordir OUTPUT_VARIABLE current_indicatordir OUTPUT_STRIP_TRAILING_WHITESPACE)
set (INDICATORDIR ${current_indicatordir})

# Configuration File and Translation
configure_file (${CMAKE_SOURCE_DIR}/config.h.cmake ${CMAKE_BINARY_DIR}/config.h)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# Setup C Libraries
add_definitions(${DEPS_CFLAGS} ${DEPS_NOVALA_CFLAGS} -DWNCK_I_KNOW_THIS_IS_UNSTABLE -include config.h)


link_libraries(${DEPS_LIBRARIES} ${DEPS_NOVALA_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS} ${DEPS_NOVALA_DIRS})

# Handle Vala Compilation
find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.16" MINIMUM)

include(ValaPrecompile)
vala_precompile (VALA_C ${EXEC_NAME}
    src/WingpanelApp.vala
    src/PanelController.vala
    src/WindowManager.vala
    src/HideManager.vala
    src/PositionManager.vala

    src/Drawing/AnimatedRenderer.vala
    src/Drawing/PanelRenderer.vala

    src/Indicator/IndicatorIface.vala
    src/Indicator/IndicatorLoader.vala
    src/Indicator/IndicatorFileModel.vala
    src/Indicator/IndicatorObjectEntry.vala
    src/Indicator/IndicatorObject.vala
    src/Indicator/IndicatorFactory.vala

    src/Services/Settings.vala
    src/Services/WMSettings.vala
    src/Services/IndicatorSorter.vala
    src/Services/AppLauncherService.vala
    src/Services/LauncherRunner.vala

    src/Widgets/WindowIface.vala
    src/Widgets/PrimaryWindow.vala
    src/Widgets/AppButtonWindow.vala
    src/Widgets/AppsButton.vala
    src/Widgets/PanelShadow.vala
    src/Widgets/MenuBar.vala
    src/Widgets/IndicatorButton.vala
    src/Widgets/IndicatorMenubar.vala
    src/Widgets/IndicatorWidget.vala
    src/Widgets/StyleClass.vala

PACKAGES
    ${WINGPANEL_DEPS}
CUSTOM_VAPIS
    vapi/config.vapi
    vapi/indicator3-0.4.vapi
OPTIONS
    -g
    --thread
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi/
)

# Settings Schema
include (GSettings)
add_schema ("org.pantheon.desktop.super-wingpanel.gschema.xml")

# Add Translation Support
add_subdirectory (po)

# Create the Executable
add_executable(${EXEC_NAME} ${VALA_C})

# Installation
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)
install (FILES ${desktop_entry} DESTINATION ${DATADIR}/applications)
install (FILES ${icon} DESTINATION ${DATADIR}/icons/hicolor/scalable/apps)
install (FILES ${icon_close} DESTINATION ${DATADIR}/super-wingpanel/icons)
install (FILES ${icon_unmax} DESTINATION ${DATADIR}/super-wingpanel/icons)



# Activate the panel
#execute_process (
#    COMMAND "gsettings" "get" "org.pantheon.cerbere" "monitored-processes"
#    COMMAND "sed" "s/'wingpanel-slim'/\\'super-wingpanel\\'/g"
#    COMMAND "sed" "s/'wingpanel'/\\'super-wingpanel\\'/g"
#    COMMAND "xargs" "-d" "\\n" "gsettings" "set" "org.pantheon.cerbere" "monitored-processes"
#    COMMAND "killall" "wingpanel"
#    COMMAND "killall" "wingpanel-slim"
#)
