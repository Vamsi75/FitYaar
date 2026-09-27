package com.fityaar.admin;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;

/**
 * Config-driven, advisory pricing used ONLY for the dashboard's estimated MRR. Real prices/limits
 * arrive later with the DB plan catalog (Milestone 6.6); keeping this in YAML means no code change
 * to tweak the estimate. Key = gym {@code planTier} label, value = monthly price in paise.
 */
@Component
@ConfigurationProperties(prefix = "app.billing")
@Getter
@Setter
public class AdminBillingProperties {
    /** e.g. { STARTER: 84000, GROWTH: 153000, PRO: 87000 }. Empty = MRR shown as 0. */
    private Map<String, Long> planPricesPaise = new HashMap<>();
}
