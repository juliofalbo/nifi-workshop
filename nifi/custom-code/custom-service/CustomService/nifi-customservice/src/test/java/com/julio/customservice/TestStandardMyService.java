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

import org.apache.nifi.reporting.InitializationException;
import org.apache.nifi.util.TestRunner;
import org.apache.nifi.util.TestRunners;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.ExpectedException;

public class TestStandardMyService {

    @Before
    public void init() {

    }

    @Test
    public void testService() throws InitializationException {
        final TestRunner runner = TestRunners.newTestRunner(TestProcessor.class);

        final StandardMyService service = new StandardMyService();
        runner.addControllerService("test-good", service);

        String token = "test-value";
        runner.setProperty(service, StandardMyService.TOKEN, token);
        runner.enableControllerService(service);

        runner.assertValid(service);
    }

    @Test
    public void testServiceErrorEmptyToken() {
        Assert.assertThrows("TOKEN cannot be empty", IllegalStateException.class, () -> {
            final TestRunner runner = TestRunners.newTestRunner(TestProcessor.class);

            final StandardMyService service = new StandardMyService();
            runner.addControllerService("test-good", service);

            String token = "";
            runner.setProperty(service, StandardMyService.TOKEN, token);
            runner.enableControllerService(service);
        });
    }

    @Test
    public void testServiceErrorNullToken() {
        Assert.assertThrows("TOKEN cannot be empty", IllegalStateException.class, () -> {
            final TestRunner runner = TestRunners.newTestRunner(TestProcessor.class);

            final StandardMyService service = new StandardMyService();
            runner.addControllerService("test-good", service);

            String token = null;
            runner.setProperty(service, StandardMyService.TOKEN, token);
            runner.enableControllerService(service);
        });
    }

    @Test
    public void testServiceErrorTokenTooLarge() {
        String token = "31231234124124124124515431";
        Assert.assertThrows("Token '" + token + "' cannot have more than 10 chars", IllegalStateException.class, () -> {

            final TestRunner runner = TestRunners.newTestRunner(TestProcessor.class);

            final StandardMyService service = new StandardMyService();
            runner.addControllerService("test-good", service);

            runner.setProperty(service, StandardMyService.TOKEN, token);
            runner.enableControllerService(service);
        });
    }

    @Test
    public void testServiceRunningProcessor() throws InitializationException {
        final TestRunner runner = TestRunners.newTestRunner(TestProcessor.class);
        runner.enqueue("test");

        final StandardMyService service = new StandardMyService();
        String token = "test-value";
        runner.addControllerService("SECRET_TOKEN_SERVICE", service);
        runner.setProperty(service, StandardMyService.TOKEN, token);
        runner.enableControllerService(service);
        runner.setProperty(TestProcessor.SECRET_TOKEN_SERVICE, "SECRET_TOKEN_SERVICE");

        runner.assertValid(service);
        runner.run();

        runner.assertTransferCount(TestProcessor.REL_FAILURE, 0);
        runner.assertTransferCount(TestProcessor.REL_SUCCESS, 1);
        runner.assertAllFlowFiles(TestProcessor.REL_SUCCESS, f -> {
            Assert.assertNotNull(f.getAttribute("token"));
            Assert.assertEquals(token, f.getAttribute("token"));
        });
    }

}
