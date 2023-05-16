const {checkPr} = require('./check')

test('fail a process definition where the first step does not have the correct name', async () => {
    const result = await checkPr('./test_deployment_processes/wrong_name.ocl')
    expect(result).toBe(false)
})

test('pass a process definition where the first step does not have the correct name', async () => {
    const result = await checkPr('./test_deployment_processes/correct_name.ocl')
    expect(result).toBe(true)
})

test('fail a process definition where the first step does not have the correct type', async () => {
    const result = await checkPr('./test_deployment_processes/correct_name_wrong_type.ocl')
    expect(result).toBe(false)
})