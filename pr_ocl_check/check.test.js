const {checkPr} = require('./check')

test('fail a process definition where the first step does not have the correct name', async () => {
    expect(() => checkPr('./test_deployment_processes/wrong_name.ocl')).toThrow()
})

test('pass a process definition where the first step does not have the correct name', async () => {
    expect(() => checkPr('./test_deployment_processes/correct_name.ocl')).not.toThrow()
})

test('fail a process definition where the first step does not have the correct type', async () => {
    expect(() =>checkPr('./test_deployment_processes/correct_name_wrong_type.ocl')).toThrow()
})