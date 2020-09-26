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

import org.apache.nifi.flowfile.FlowFile;
import org.apache.nifi.util.FlowFileValidator;
import org.apache.nifi.util.MockFlowFile;
import org.apache.nifi.util.TestRunner;
import org.apache.nifi.util.TestRunners;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


public class MyProcessorTest {

    private TestRunner testRunner;

    @Before
    public void init() {
        testRunner = TestRunners.newTestRunner(MyProcessor.class);
    }

    @Test
    public void processorShouldWorkFine() throws FileNotFoundException {

        final String filename = "firstTest.json";
        MockFlowFile flowFile = testRunner.enqueue(new FileInputStream(new File("src/test/resources/" + filename)));
        Map<String, String> attrs = new HashMap<>() {
            {
                put("filename", filename);
            }
        };
        flowFile.putAttributes(attrs);

        testRunner.setValidateExpressionUsage(false);
        testRunner.setProperty(MyProcessor.TAGS_STARTING_WITH, "l");


        testRunner.assertValid();
        testRunner.run();
        testRunner.assertTransferCount(MyProcessor.REL_FAILURE, 0);
        testRunner.assertAllFlowFiles(MyProcessor.REL_SUCCESS, f -> {
            Assert.assertNotNull(f.getAttribute("treated"));
            Assert.assertEquals("true", f.getAttribute("treated"));
        });

        List<MockFlowFile> flowFilesForRelationship = testRunner.getFlowFilesForRelationship(MyProcessor.REL_SUCCESS);
        Assert.assertEquals(1, flowFilesForRelationship.size());
        Assert.assertEquals("laborum,labore,labore", flowFilesForRelationship.get(0).getContent());
    }

    @Test
    public void flowfileShouldGoToFailedRelDueNoTags() throws FileNotFoundException {

        final String filename = "noTags.json";
        MockFlowFile flowFile = testRunner.enqueue(new FileInputStream(new File("src/test/resources/" + filename)));
        Map<String, String> attrs = new HashMap<String, String>() {
            {
                put("filename", filename);
            }
        };
        flowFile.putAttributes(attrs);

        testRunner.setValidateExpressionUsage(false);
        testRunner.setProperty(MyProcessor.TAGS_STARTING_WITH, "l");


        testRunner.assertValid();
        testRunner.run();
        testRunner.assertTransferCount(MyProcessor.REL_SUCCESS, 0);
        testRunner.assertTransferCount(MyProcessor.REL_FAILURE, 1);
        testRunner.assertAllFlowFiles(MyProcessor.REL_FAILURE, f -> {
            Assert.assertNotNull(f.getAttribute("treated"));
            Assert.assertEquals("false", f.getAttribute("treated"));
        });
    }

    @Test
    public void flowfileShouldGoToFailedRelDueInvalidFormat() throws FileNotFoundException {

        final String filename = "invalid.json";
        MockFlowFile flowFile = testRunner.enqueue(new FileInputStream(new File("src/test/resources/" + filename)));
        Map<String, String> attrs = new HashMap<String, String>() {
            {
                put("filename", filename);
            }
        };
        flowFile.putAttributes(attrs);

        testRunner.setValidateExpressionUsage(false);
        testRunner.setProperty(MyProcessor.TAGS_STARTING_WITH, "l");


        testRunner.assertValid();
        testRunner.run();
        testRunner.assertTransferCount(MyProcessor.REL_SUCCESS, 0);
        testRunner.assertTransferCount(MyProcessor.REL_FAILURE, 1);
        testRunner.assertAllFlowFiles(MyProcessor.REL_FAILURE, f -> {
            Assert.assertNotNull(f.getAttribute("treated"));
            Assert.assertEquals("false", f.getAttribute("treated"));
        });
    }

}
