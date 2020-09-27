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

import com.julio.customservice.ICustomControllerService;
import org.apache.nifi.annotation.lifecycle.OnEnabled;
import org.apache.nifi.components.PropertyDescriptor;
import org.apache.nifi.controller.AbstractControllerService;
import org.apache.nifi.controller.ConfigurationContext;
import org.apache.nifi.processor.exception.ProcessException;
import org.apache.nifi.processor.util.StandardValidators;
import org.apache.nifi.reporting.InitializationException;
import org.apache.nifi.util.MockFlowFile;
import org.apache.nifi.util.TestRunner;
import org.apache.nifi.util.TestRunners;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.util.*;


public class CustomProcessorTest {

    private TestRunner testRunner;

    @Before
    public void init() {
        testRunner = TestRunners.newTestRunner(CustomProcessor.class);
    }

    @Test
    public void processorShouldWorkFine() throws FileNotFoundException, InitializationException {

        final String filename = "firstTest.json";
        MockFlowFile flowFile = testRunner.enqueue(new FileInputStream(new File("src/test/resources/" + filename)));
        Map<String, String> attrs = new HashMap<String, String>() {
            {
                put("filename", filename);
            }
        };
        flowFile.putAttributes(attrs);

        testRunner.setValidateExpressionUsage(false);
        testRunner.setProperty(CustomProcessor.TAGS_STARTING_WITH, "l");

        configureCustomControllerService();

        testRunner.assertValid();
        testRunner.run();
        testRunner.assertTransferCount(CustomProcessor.REL_FAILURE, 0);
        testRunner.assertAllFlowFiles(CustomProcessor.REL_SUCCESS, f -> {
            Assert.assertNotNull(f.getAttribute("treated"));
            Assert.assertEquals("true", f.getAttribute("treated"));
        });

        List<MockFlowFile> flowFilesForRelationship = testRunner.getFlowFilesForRelationship(CustomProcessor.REL_SUCCESS);
        Assert.assertEquals(1, flowFilesForRelationship.size());
        Assert.assertEquals("laborum,labore,labore", flowFilesForRelationship.get(0).getContent());
    }

    @Test
    public void flowfileShouldGoToFailedRelDueNoTags() throws FileNotFoundException, InitializationException {

        final String filename = "noTags.json";
        MockFlowFile flowFile = testRunner.enqueue(new FileInputStream(new File("src/test/resources/" + filename)));
        Map<String, String> attrs = new HashMap<String, String>() {
            {
                put("filename", filename);
            }
        };
        flowFile.putAttributes(attrs);

        testRunner.setValidateExpressionUsage(false);
        testRunner.setProperty(CustomProcessor.TAGS_STARTING_WITH, "l");

        configureCustomControllerService();

        testRunner.assertValid();
        testRunner.run();
        testRunner.assertTransferCount(CustomProcessor.REL_SUCCESS, 0);
        testRunner.assertTransferCount(CustomProcessor.REL_FAILURE, 1);
        testRunner.assertAllFlowFiles(CustomProcessor.REL_FAILURE, f -> {
            Assert.assertNotNull(f.getAttribute("treated"));
            Assert.assertEquals("false", f.getAttribute("treated"));
        });
    }

    @Test
    public void flowfileShouldGoToFailedRelDueInvalidFormat() throws FileNotFoundException, InitializationException {

        final String filename = "invalid.json";
        MockFlowFile flowFile = testRunner.enqueue(new FileInputStream(new File("src/test/resources/" + filename)));
        Map<String, String> attrs = new HashMap<String, String>() {
            {
                put("filename", filename);
            }
        };
        flowFile.putAttributes(attrs);

        testRunner.setValidateExpressionUsage(false);
        testRunner.setProperty(CustomProcessor.TAGS_STARTING_WITH, "l");

        configureCustomControllerService();

        testRunner.assertValid();
        testRunner.run();
        testRunner.assertTransferCount(CustomProcessor.REL_SUCCESS, 0);
        testRunner.assertTransferCount(CustomProcessor.REL_FAILURE, 1);
        testRunner.assertAllFlowFiles(CustomProcessor.REL_FAILURE, f -> {
            Assert.assertNotNull(f.getAttribute("treated"));
            Assert.assertEquals("false", f.getAttribute("treated"));
        });
    }

    private void configureCustomControllerService() throws InitializationException {
        final MockMyService service = new MockMyService();
        testRunner.addControllerService("SECRET_TOKEN_SERVICE", service);
        testRunner.setProperty(service, MockMyService.TOKEN, CustomProcessor.TOKEN);
        testRunner.enableControllerService(service);
        testRunner.setProperty(CustomProcessor.SECRET_TOKEN_SERVICE, "SECRET_TOKEN_SERVICE");
    }

}

class MockMyService extends AbstractControllerService implements ICustomControllerService {

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
    public String getToken() throws ProcessException {
        return context.getProperty(TOKEN).getValue();
    }

    @OnEnabled
    public void onEnabled(final ConfigurationContext context) {
        this.context = context;
    }

    @Override
    protected List<PropertyDescriptor> getSupportedPropertyDescriptors() {
        return properties;
    }
}
