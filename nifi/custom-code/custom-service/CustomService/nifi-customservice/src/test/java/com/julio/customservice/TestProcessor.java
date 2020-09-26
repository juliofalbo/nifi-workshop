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

import java.util.*;

import org.apache.nifi.components.PropertyDescriptor;
import org.apache.nifi.flowfile.FlowFile;
import org.apache.nifi.processor.*;
import org.apache.nifi.processor.exception.ProcessException;

public class TestProcessor extends AbstractProcessor {

    public static final PropertyDescriptor SECRET_TOKEN_SERVICE = new PropertyDescriptor
        .Builder().name("SECRET_TOKEN_SERVICE")
                  .displayName("Tags Starting With")
                  .description("Only get tags which starts with")
                  .identifiesControllerService(StandardMyService.class)
                  .required(true)
                  .build();

    public static final Relationship REL_SUCCESS = new Relationship.Builder()
        .name("success")
        .description("FlowFile was processed successfully")
        .build();

    public static final Relationship REL_FAILURE = new Relationship.Builder()
        .name("failure")
        .description("FlowFile was processed unsuccessfully")
        .build();

    private Set<Relationship> relationships;

    @Override
    protected void init(final ProcessorInitializationContext context) {
        final Set<Relationship> relationships = new HashSet<>();
        relationships.add(REL_SUCCESS);
        relationships.add(REL_FAILURE);
        this.relationships = Collections.unmodifiableSet(relationships);
    }

    @Override
    public void onTrigger(ProcessContext context, ProcessSession session) throws ProcessException {
        FlowFile flowFile = session.get();
        final StandardMyService secretTokenService = context.getProperty(SECRET_TOKEN_SERVICE).asControllerService(StandardMyService.class);
        String token = secretTokenService.getToken();
        if(token == null || token
                                                                      .isEmpty()){
            session.transfer(flowFile, REL_FAILURE);
        } else {
            session.putAttribute(flowFile, "token", token);
            session.transfer(flowFile, REL_SUCCESS);
        }
    }

    @Override
    public Set<Relationship> getRelationships() {
        return this.relationships;
    }

    @Override
    protected List<PropertyDescriptor> getSupportedPropertyDescriptors() {
        List<PropertyDescriptor> propDescs = new ArrayList<>();
        propDescs.add(new PropertyDescriptor.Builder()
                .name("MyService test processor")
                .description("MyService test processor")
                .identifiesControllerService(MyService.class)
                .required(true)
                .build());
        return propDescs;
    }

}
