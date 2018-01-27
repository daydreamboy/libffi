#!/bin/sh

# @see https://stackoverflow.com/a/46037941
# @see https://gist.github.com/cromandini/1a9c4aeab27ca84f5d79

# Set bash script to exit immediately if any commands fail.
set -e

UNIVERSAL_OUTPUTFOLDER=${BUILD_DIR}/${CONFIGURATION}-iphoneuniversal

# only build configuration is Debug to create universal, becase AppStore not accept fat arch
if [ "Debug" == ${CONFIGURATION} ]; then
    # make sure the output directory exists
    mkdir -p "${UNIVERSAL_OUTPUTFOLDER}"

    # Next, work out if we're in SIM or DEVICE
    if [ "false" == ${ALREADYINVOKED:-false} ]; then

        export ALREADYINVOKED="true"

        additional_arch=${PLATFORM_NAME}
        if [ ${PLATFORM_NAME} = "iphonesimulator" ]; then
            additional_arch='iphoneos'
        else
            additional_arch='iphonesimulator'
        fi
        
        xcodebuild -target "${TARGET_NAME}" -configuration ${CONFIGURATION} -sdk ${additional_arch} ONLY_ACTIVE_ARCH=NO BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" OBJROOT="${OBJROOT}" clean build
        
        # Step 2. Copy the library file and `include` folder (from iphoneos or iphonesimulator build) to the universal folder
        rsync -arv "${BUILD_DIR}/${CONFIGURATION}-${additional_arch}/lib${PRODUCT_NAME}.a" "${UNIVERSAL_OUTPUTFOLDER}/"
		rsync -arv "${BUILD_DIR}/${CONFIGURATION}-${additional_arch}/include" "${UNIVERSAL_OUTPUTFOLDER}/"

        # cp -R "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PRODUCT_NAME}.framework" "${UNIVERSAL_OUTPUTFOLDER}/"

        # Step 3. Copy Swift modules from iphonesimulator build (if it exists) to the copied framework directory
        SIMULATOR_SWIFT_MODULES_DIR="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${PRODUCT_NAME}.framework/Modules/${PROJECT_NAME}.swiftmodule/."
        if [ -d "${SIMULATOR_SWIFT_MODULES_DIR}" ]; then
            rsync -arv "${SIMULATOR_SWIFT_MODULES_DIR}" "${UNIVERSAL_OUTPUTFOLDER}/${PRODUCT_NAME}.framework/Modules/${PRODUCT_NAME}.swiftmodule"
        fi

        # Step 4. Create universal binary file using lipo and place the combined executable in the copied framework directory
        lipo -create -output "${UNIVERSAL_OUTPUTFOLDER}/lib${PRODUCT_NAME}.a" "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/lib${PRODUCT_NAME}.a" "${BUILD_DIR}/${CONFIGURATION}-iphoneos/lib${PRODUCT_NAME}.a"

        # Step 7. Remove build folder
        rm -rf build/
    fi
fi
