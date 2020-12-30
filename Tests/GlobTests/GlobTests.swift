import Foundation
import XCTest
@testable import Glob

//
//  Created by Eric Firestone on 3/22/16.
//  Copyright © 2016 Square, Inc. All rights reserved.
//  Released under the Apache v2 License.
//
//  Adapted from https://gist.github.com/blakemerryman/76312e1cbf8aec248167

import XCTest

class GlobTests : XCTestCase {

    let tmpFiles = ["foo", "bar", "baz", "dir1/file1.ext", "dir1/dir2/dir3/file2.ext"]
    var tmpDir: URL!
    
    override func setUp() {
        super.setUp()

        tmpDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
        let deepest = tmpDir.appendingPathComponent("dir1/dir2/dir3")
        do {
            try FileManager.default.createDirectory(at: deepest, withIntermediateDirectories: true, attributes: nil)
        } catch {
            XCTFail("Could not create temporary directory for testing: \(error)")
        }

        for file in tmpFiles {
            let path = tmpDir.appendingPathComponent(file).path
            if !FileManager.default.createFile(atPath: path, contents: Data()) {
                XCTFail("Could not create temporary file at path: '\(path)'")
            }
        }
    }
    
    override func tearDown() {
        if let tmpDir = tmpDir {
            do {
                try FileManager.default.removeItem(at: tmpDir)
            } catch {
                XCTFail("Could not remove temporary directory: \(error)")
            }
        }
        super.tearDown()
    }

    private func test(pattern: String, behavior: Glob.Behavior, expected: [String]) {
        testWithPrefix("\(tmpDir.path)/", pattern: pattern, behavior: behavior, expected: expected)

        let originalPath = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tmpDir.path)
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalPath)
        }

        testWithPrefix("./", pattern: pattern, behavior: behavior, expected: expected)
        testWithPrefix("", pattern: pattern, behavior: behavior, expected: expected)
    }

    private func testWithPrefix(_ prefix: String, pattern: String, behavior: Glob.Behavior, expected: [String]) {
        let pattern = "\(prefix)\(pattern)"
        let glob = Glob(pattern: pattern, behavior: behavior)
        XCTAssertEqual(glob.paths, expected.map { "\(prefix)\($0)" })
    }
    
    func testBraces() {
        let pattern = "\(tmpDir.path)/ba{r,y,z}"
        let glob = Glob(pattern: pattern)
        var contents = [String]()
        for file in glob {
            contents.append(file)
        }
        XCTAssertEqual(contents, ["\(tmpDir.path)/bar", "\(tmpDir.path)/baz"], "matching with braces failed")
    }
    
    func testNothingMatches() {
        let pattern = "\(tmpDir.path)/nothing"
        let glob = Glob(pattern: pattern)
        var contents = [String]()
        for file in glob {
            contents.append(file)
        }
        XCTAssertEqual(contents, [], "expected empty list of files")
    }
    
    func testDirectAccess() {
        let pattern = "\(tmpDir.path)/ba{r,y,z}"
        let glob = Glob(pattern: pattern)
        XCTAssertEqual(glob.paths, ["\(tmpDir.path)/bar", "\(tmpDir.path)/baz"], "matching with braces failed")
    }
    
    func testIterateTwice() {
        let pattern = "\(tmpDir.path)/ba{r,y,z}"
        let glob = Glob(pattern: pattern)
        var contents1 = [String]()
        var contents2 = [String]()
        for file in glob {
            contents1.append(file)
        }
        let filesAfterOnce = glob.paths
        for file in glob {
            contents2.append(file)
        }
        XCTAssertEqual(contents1, contents2, "results for calling for-in twice are the same")
        XCTAssertEqual(glob.paths, filesAfterOnce, "calling for-in twice doesn't only memoizes once")
    }
    
    func testIndexing() {
        let pattern = "\(tmpDir.path)/ba{r,y,z}"
        let glob = Glob(pattern: pattern)
        guard glob.count == 2 else {
            return XCTFail("Exptected 2 results")
        }
        XCTAssertEqual(glob[0], "\(tmpDir.path)/bar", "indexing")
    }
    
    // MARK: - Globstar - Bash v3
    
    func testGlobstarBashV3NoSlash() {
        // Should be the equivalent of "ls -d -1 /(tmpdir)/**"
        test(pattern: "**",
             behavior: GlobBehaviorBashV3,
             expected: ["bar", "baz", "dir1/", "foo"])
    }
    
    func testGlobstarBashV3WithSlash() {
        // Should be the equivalent of "ls -d -1 /(tmpdir)/**/"
        test(pattern: "**/",
             behavior: GlobBehaviorBashV3,
             expected: ["dir1/"])
    }
    
    func testGlobstarBashV3WithSlashAndWildcard() {
        // Should be the equivalent of "ls -d -1 /(tmpdir)/**/*"
        test(pattern: "**/*",
             behavior: GlobBehaviorBashV3,
             expected: ["dir1/dir2/", "dir1/file1.ext"])
    }
    
    func testDoubleGlobstarBashV3() {
        test(pattern: "**/dir2/**/*",
             behavior: GlobBehaviorBashV3,
             expected: ["dir1/dir2/dir3/file2.ext"])
    }
    
    // MARK: - Globstar - Bash v4
    
    func testGlobstarBashV4NoSlash() {
        // Should be the equivalent of "ls -d -1 /(tmpdir)/**"
        test(pattern: "**",
             behavior: GlobBehaviorBashV4,
             expected: ["",
                        "bar",
                        "baz",
                        "dir1/",
                        "dir1/dir2/",
                        "dir1/dir2/dir3/",
                        "dir1/dir2/dir3/file2.ext",
                        "dir1/file1.ext",
                        "foo"
        ])
    }
    
    func testGlobstarBashV4WithSlash() {
        // Should be the equivalent of "ls -d -1 /(tmpdir)/**/"
        test(pattern: "**/",
             behavior: GlobBehaviorBashV4,
             expected: [
                "",
                "dir1/",
                "dir1/dir2/",
                "dir1/dir2/dir3/",
        ])
    }
    
    func testGlobstarBashV4WithSlashAndWildcard() {
        // Should be the equivalent of "ls -d -1 /(tmpdir)/**/*"
        test(pattern: "**/*",
             behavior: GlobBehaviorBashV4,
             expected: [
                "bar",
                "baz",
                "dir1/",
                "dir1/dir2/",
                "dir1/dir2/dir3/",
                "dir1/dir2/dir3/file2.ext",
                "dir1/file1.ext",
                "foo",
        ])
    }
    
    func testDoubleGlobstarBashV4() {
        test(pattern: "**/dir2/**/*",
             behavior: GlobBehaviorBashV4,
             expected: [
                "dir1/dir2/dir3/",
                "dir1/dir2/dir3/file2.ext",
        ])
    }
    
    // MARK: - Globstar - Gradle
    
    func testGlobstarGradleNoSlash() {
        // Should be the equivalent of 
        // FileTree tree = project.fileTree((Object)'/tmp') {
        //   include 'glob-test.7m0Lp/**'
        // }
        //
        // Note that the sort order currently matches Bash and not Gradle
        test(pattern: "**",
             behavior: GlobBehaviorGradle,
             expected: [
                "bar",
                "baz",
                "dir1/dir2/dir3/file2.ext",
                "dir1/file1.ext",
                "foo",
        ])
    }
    
    func testGlobstarGradleWithSlash() {
        // Should be the equivalent of 
        // FileTree tree = project.fileTree((Object)'/tmp') {
        //   include 'glob-test.7m0Lp/**/'
        // }
        //
        // Note that the sort order currently matches Bash and not Gradle
        test(pattern: "**/",
             behavior: GlobBehaviorGradle,
             expected: [
                "bar",
                "baz",
                "dir1/dir2/dir3/file2.ext",
                "dir1/file1.ext",
                "foo",
        ])
    }
    
    func testGlobstarGradleWithSlashAndWildcard() {
        // Should be the equivalent of 
        // FileTree tree = project.fileTree((Object)'/tmp') {
        //   include 'glob-test.7m0Lp/**/*'
        // }
        //
        // Note that the sort order currently matches Bash and not Gradle
        test(pattern: "**/*",
             behavior: GlobBehaviorGradle,
             expected: [
                "bar",
                "baz",
                "dir1/dir2/dir3/file2.ext",
                "dir1/file1.ext",
                "foo",
        ])
    }
    
    func testDoubleGlobstarGradle() {
        // Should be the equivalent of
        // FileTree tree = project.fileTree((Object)'/tmp') {
        //   include 'glob-test.7m0Lp/**/dir2/**/*'
        // }
        //
        // Note that the sort order currently matches Bash and not Gradle
        test(pattern: "**/dir2/**/*",
             behavior: GlobBehaviorGradle,
             expected: [
                "dir1/dir2/dir3/file2.ext",
        ])
    }
}

extension GlobTests {
	static var allTests : [(String, (GlobTests) -> () throws -> Void)] {
		return [
			("testBraces", testBraces),
			("testNothingMatches", testNothingMatches),
			("testDirectAccess", testDirectAccess),
			("testIterateTwice", testIterateTwice),
			("testIndexing", testIndexing),
			("testGlobstarBashV3NoSlash", testGlobstarBashV3NoSlash),
			("testGlobstarBashV3WithSlash", testGlobstarBashV3WithSlash),
			("testGlobstarBashV3WithSlashAndWildcard", testGlobstarBashV3WithSlashAndWildcard),
			("testDoubleGlobstarBashV3", testDoubleGlobstarBashV3),
			("testGlobstarBashV4NoSlash", testGlobstarBashV4NoSlash),
			("testGlobstarBashV4WithSlash", testGlobstarBashV4WithSlash),
			("testGlobstarBashV4WithSlashAndWildcard", testGlobstarBashV4WithSlashAndWildcard),
			("testDoubleGlobstarBashV4", testDoubleGlobstarBashV4),
			("testGlobstarGradleNoSlash", testGlobstarGradleNoSlash),
			("testGlobstarGradleWithSlash", testGlobstarGradleWithSlash),
			("testGlobstarGradleWithSlashAndWildcard", testGlobstarGradleWithSlashAndWildcard),
			("testDoubleGlobstarGradle", testDoubleGlobstarGradle),
		]
	}
}
