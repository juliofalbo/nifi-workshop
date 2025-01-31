/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.julio.customservice;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;

import org.apache.nifi.annotation.documentation.CapabilityDescription;
import org.apache.nifi.annotation.documentation.Tags;
import org.apache.nifi.annotation.lifecycle.OnDisabled;
import org.apache.nifi.annotation.lifecycle.OnEnabled;
import org.apache.nifi.components.PropertyDescriptor;
import org.apache.nifi.components.ValidationContext;
import org.apache.nifi.components.ValidationResult;
import org.apache.nifi.controller.AbstractControllerService;
import org.apache.nifi.controller.ConfigurationContext;
import org.apache.nifi.processor.exception.ProcessException;
import org.apache.nifi.processor.util.StandardValidators;
import org.apache.nifi.reporting.InitializationException;

@Tags({ "example" })
@CapabilityDescription("Example ControllerService implementation of MyService.")
public class CustomControllerService extends AbstractControllerService implements ICustomControllerService {

    public static final PropertyDescriptor TOKEN = new PropertyDescriptor
        .Builder().name("TOKEN")
                  .displayName("Token")
                  .description("Secret Token")
                  .required(true)
                  .addValidator(StandardValidators.NON_EMPTY_VALIDATOR)
                  .build();

    private static final List<PropertyDescriptor> properties;

    static {
        final List<PropertyDescriptor> props = new ArrayList<>();
        props.add(TOKEN);
        properties = Collections.unmodifiableList(props);
    }

    private ConfigurationContext context;

    @Override
    protected List<PropertyDescriptor> getSupportedPropertyDescriptors() {
        return properties;
    }

    @Override
    protected Collection<ValidationResult> customValidate(final ValidationContext validationContext) {
        List<ValidationResult> results = new ArrayList<>(super.customValidate(validationContext));

        String value = validationContext.getProperty(TOKEN)
                              .getValue();

        if (value.length() > 10) {
            results.add(new ValidationResult.Builder()
                            .subject("Token too large")
                            .valid(false)
                            .explanation(String.format("Token '%s' cannot have more than 10 chars", value))
                            .build());
        }
        return results;
    }

    /**
     * @param context the configuration context
     * @throws InitializationException if unable to create a database connection
     */
    @OnEnabled
    public void onEnabled(final ConfigurationContext context) throws InitializationException {
        this.context = context;
    }

    @OnDisabled
    public void shutdown() {

    }

    @Override
    public String getToken() throws ProcessException {
        return context.getProperty(TOKEN)
                      .getValue();
    }

}
