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
package com.julio.processors.custom;

import com.julio.customservice.MyService;
import org.apache.nifi.annotation.behavior.ReadsAttribute;
import org.apache.nifi.annotation.behavior.ReadsAttributes;
import org.apache.nifi.annotation.behavior.WritesAttribute;
import org.apache.nifi.annotation.behavior.WritesAttributes;
import org.apache.nifi.annotation.documentation.CapabilityDescription;
import org.apache.nifi.annotation.documentation.SeeAlso;
import org.apache.nifi.annotation.documentation.Tags;
import org.apache.nifi.annotation.lifecycle.OnScheduled;
import org.apache.nifi.components.PropertyDescriptor;
import org.apache.nifi.components.ValidationContext;
import org.apache.nifi.components.ValidationResult;
import org.apache.nifi.expression.ExpressionLanguageScope;
import org.apache.nifi.flowfile.FlowFile;
import org.apache.nifi.processor.*;
import org.apache.nifi.processor.exception.ProcessException;
import org.apache.nifi.processor.util.StandardValidators;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.concurrent.atomic.AtomicReference;

@Tags({ "example" })
@CapabilityDescription("Provide a description")
@SeeAlso({})
@ReadsAttributes({ @ReadsAttribute(attribute = "", description = "") })
@WritesAttributes({ @WritesAttribute(attribute = "", description = "") })
public class MyProcessor extends AbstractProcessor {

    // This is the property that will be added by the User via UI
    public static final PropertyDescriptor TAGS_STARTING_WITH = new PropertyDescriptor
        .Builder().name("TAGS_STARTING_WITH")
                  .displayName("Tags Starting With")
                  .description("Only get tags which starts with")
                  .required(true)
                  .addValidator(StandardValidators.NON_EMPTY_VALIDATOR)
                  .expressionLanguageSupported(ExpressionLanguageScope.FLOWFILE_ATTRIBUTES)
                  .build();

    public static final PropertyDescriptor SECRET_TOKEN_SERVICE = new PropertyDescriptor
        .Builder().name("SECRET_TOKEN_SERVICE")
                  .displayName("Tags Starting With")
                  .description("Only get tags which starts with")
                  .identifiesControllerService(MyService.class)
                  .required(true)
                  .build();

    // This is the variable responsible to tell NiFi what are the Relationships supported for this Processor, like: success, failure, original, output, and etc.
    // Note: Can be anything, just choose the best words for your Processor.
    public static final Relationship REL_SUCCESS = new Relationship.Builder()
        .name("success")
        .description("FlowFile was processed successfully")
        .build();

    public static final Relationship REL_FAILURE = new Relationship.Builder()
        .name("failure")
        .description("FlowFile was processed unsuccessfully")
        .build();

    protected static String TOKEN = "nifitoken";

    private List<PropertyDescriptor> descriptors;

    private Set<Relationship> relationships;

    // Here basically we use to start the properties and relationships
    @Override
    protected void init(final ProcessorInitializationContext context) {
        final List<PropertyDescriptor> descriptors = new ArrayList<PropertyDescriptor>();
        descriptors.add(TAGS_STARTING_WITH);
        descriptors.add(SECRET_TOKEN_SERVICE);
        this.descriptors = Collections.unmodifiableList(descriptors);

        final Set<Relationship> relationships = new HashSet<>();
        relationships.add(REL_SUCCESS);
        relationships.add(REL_FAILURE);
        this.relationships = Collections.unmodifiableSet(relationships);
    }

    @Override
    public Set<Relationship> getRelationships() {
        return this.relationships;
    }

    @Override
    public final List<PropertyDescriptor> getSupportedPropertyDescriptors() {
        return descriptors;
    }

    // The @OnScheduled method will be called whenever the processor is scheduled to be run
    // //i.e. a user clicks/invokes the API to "start" the processor
    @OnScheduled
    public void onScheduled(final ProcessContext context) {

    }

    @Override
    protected Collection<ValidationResult> customValidate(ValidationContext validationContext) {
        final MyService secretTokenService = validationContext.getProperty(SECRET_TOKEN_SERVICE)
                                                                      .asControllerService(MyService.class);


        List<ValidationResult> results = new ArrayList<>(super.customValidate(validationContext));

        if (!isValidToken(secretTokenService)) {
            results.add(new ValidationResult.Builder()
                            .subject("Invalid Token")
                            .valid(false)
                            .explanation("Invalid Token")
                            .build());
        }

        return results;
    }

    //This method will be called every time that a new FlowFill reach the Processor
    @Override
    public void onTrigger(final ProcessContext context, final ProcessSession session) throws ProcessException {
        FlowFile flowFile = session.get();
        if (flowFile == null) {
            return;
        }

        try {
            AtomicReference<String> errorMessage = new AtomicReference<>("");

            String startsWith = context.getProperty(TAGS_STARTING_WITH)
                                       .getValue();

            FlowFile newFlowFile = session.write(flowFile, (inputStream, outputStream) -> {
                JSONParser jsonParser = new JSONParser();
                try {
                    JSONObject jsonObject = (JSONObject) jsonParser.parse(new InputStreamReader(inputStream, StandardCharsets.UTF_8));
                    JSONArray tags = (JSONArray) jsonObject.get("tags");
                    long count = tags.size();

                    if (count == 0) {
                        throw new RuntimeException("Tags cannot be empty. Bad Data");
                    }

                    String selectedTags = (String) tags.stream()
                                                       .filter(tag -> tag.toString()
                                                                         .startsWith(startsWith))
                                                       .reduce((o, o2) -> o + "," + o2)
                                                       .orElse("");

                    outputStream.write(selectedTags.getBytes(StandardCharsets.UTF_8));
                } catch (ParseException e) {
                    errorMessage.set(e.getMessage());
                }
            });

            if (!errorMessage.get()
                             .isEmpty()) {
                throw new RuntimeException(errorMessage.get());
            } else {
                flowFile = newFlowFile;
            }

            flowFile = session.putAttribute(flowFile, "treated", "true");
            session.transfer(flowFile, REL_SUCCESS);
        } catch (Exception ex) {
            flowFile = session.putAttribute(flowFile, "treated", "false");
            String message = ex.getMessage();
            if (message == null) {
                message = ex.getClass()
                            .getName();
            }
            flowFile = session.putAttribute(flowFile, "error.message", message);
            session.transfer(flowFile, REL_FAILURE);
        }
    }

    private boolean isValidToken(MyService secretTokenService) {
        if (secretTokenService.getToken() == null
            || secretTokenService.getToken()
                                 .isEmpty()
            || !TOKEN.equals(secretTokenService.getToken())) {
            return false;
        }

        return true;
    }
}
