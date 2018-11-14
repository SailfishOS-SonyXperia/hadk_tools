hadk_config_valid()
{
    if [ ! $VENDOR ] ; then
        return 1
    fi


    if [ ! $DEVICE ] ; then
        return 1
    fi

    if [ ! $HABUILD_DEVICE ] ; then
        return 1
    fi

    if [ ! $EDGE ] ; then
        return 1
    fi

            
    if [ ! $HYBRIS_ANDROID_URL ] ; then
        return 1
    fi


    if [ ! $HYBRIS_ANDROID_BRANCH ] ; then
        return 1
    fi
}
