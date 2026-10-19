package com.farsitel.bazaar.referrerprovider;

import android.os.Bundle;

interface ReferrerProviderService {
    /**
     * Returns the referrer data for given package name.
     * @param packageName The package name of the user application.
     * @return Bundle containing install_referrer, referrer_click_timestamp_milliseconds,
     *         install_begin_timestamp_milliseconds, and app_version.
     */
    Bundle getReferrer(String packageName);

    /**
     * Consumes the referrer data for the given package name.
     */
    void consumeReferrer(String packageName, long installTimeMilliSeconds);
}
